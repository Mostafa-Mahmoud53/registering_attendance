// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as native_http;
import '../Auth/auth_storage.dart';
import '../Auth/api_service.dart';
import '../Auth/main_file.dart';
import 'app_router.dart';

const String _sessionExpiredMessage =
    'Your session has expired. Please log in again.';
const String _noInternetMessage = 'No internet connection. Check your network.';
const String _timeoutMessage = 'Request timed out. Please try again.';
const String _serverErrorMessage = 'Server error. Please try again later.';

native_http.Response _offlineResponse() {
  return native_http.Response(
    jsonEncode({"message": _noInternetMessage}),
    503,
  );
}

native_http.Response _timeoutResponse() {
  return native_http.Response(
    jsonEncode({"message": _timeoutMessage}),
    504,
  );
}

native_http.Response _serverErrorResponse() {
  return native_http.Response(
    jsonEncode({"message": _serverErrorMessage}),
    502,
  );
}

native_http.Response _sessionExpiredResponse() {
  return native_http.Response(
    jsonEncode({"message": _sessionExpiredMessage}),
    401,
  );
}

native_http.Response _normalizeResponse(native_http.Response res) {
  if (res.statusCode >= 500 && res.statusCode <= 599) {
    return _serverErrorResponse();
  }
  return res;
}

Future<native_http.Response> _withAuthRefresh(
  Future<native_http.Response> Function(Map<String, String>? currentHeaders) request,
  Map<String, String>? headers,
) async {
  final res = await request(headers);
  if (res.statusCode == 401) {
    final refreshed = await _attemptRefresh();
    if (refreshed) {
      final newToken = await AuthStorage.getToken();
      final updatedHeaders = Map<String, String>.from(headers ?? {});
      updatedHeaders['Authorization'] = 'Bearer $newToken';
      
      print('🔄 Retrying request with new token...');
      return _normalizeResponse(await request(updatedHeaders));
    }
    _handleAuthExpired();
    return _sessionExpiredResponse();
  }
  return _normalizeResponse(res);
}

Future<native_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  try {
    return await _withAuthRefresh(
      (currentHeaders) => native_http.get(url, headers: currentHeaders)
          .timeout(const Duration(seconds: 30)),
      headers,
    );
  } on SocketException {
    return _offlineResponse();
  } on TimeoutException {
    return _timeoutResponse();
  } catch (e) {
    return _timeoutResponse();
  }
}

Future<native_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  try {
    return await _withAuthRefresh(
      (currentHeaders) => native_http.post(url, headers: currentHeaders, body: body, encoding: encoding)
          .timeout(const Duration(seconds: 30)),
      headers,
    );
  } on SocketException {
    return _offlineResponse();
  } on TimeoutException {
    return _timeoutResponse();
  } catch (e) {
    return _timeoutResponse();
  }
}

Future<native_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  try {
    return await _withAuthRefresh(
      (currentHeaders) => native_http.put(url, headers: currentHeaders, body: body, encoding: encoding)
          .timeout(const Duration(seconds: 30)),
      headers,
    );
  } on SocketException {
    return _offlineResponse();
  } on TimeoutException {
    return _timeoutResponse();
  } catch (e) {
    return _timeoutResponse();
  }
}

Future<native_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  try {
    return await _withAuthRefresh(
      (currentHeaders) => native_http.delete(url, headers: currentHeaders, body: body, encoding: encoding)
          .timeout(const Duration(seconds: 30)),
      headers,
    );
  } on SocketException {
    return _offlineResponse();
  } on TimeoutException {
    return _timeoutResponse();
  } catch (e) {
    return _timeoutResponse();
  }
}

bool _isRedirecting = false;

void _handleAuthExpired() {
  if (_isRedirecting) return;
  _isRedirecting = true;

  AuthStorage.clearUserData();
  final messenger = AppRouter.messengerKey.currentState;
  if (messenger != null) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(_sessionExpiredMessage),
      ),
    );
  }
  final navigator = AppRouter.navigatorKey.currentState;
  if (navigator == null) return;
  
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const ActivationLoginPage(showLogin: true)),
    (route) => false,
  );
}

Future<bool>? _refreshFuture;

Future<bool> _attemptRefresh() async {
  if (_refreshFuture != null) {
    return await _refreshFuture!;
  }

  _refreshFuture = _performRefresh();
  final result = await _refreshFuture!;
  _refreshFuture = null;
  return result;
}

Future<bool> _performRefresh() async {
  try {
    final userData = await AuthStorage.getUserData();
    if (userData == null) return false;

    final currentToken = userData['token'];
    final currentRefresh = userData['refreshToken'];
    final deviceId = userData['deviceId'];

    if (currentToken == null || currentRefresh == null || deviceId == null) {
      return false;
    }

    final response = await native_http.post(
      Uri.parse('${ApiService.baseUrl}/Auth/refresh-token'),
      headers: {'accept': '*/*', 'Content-Type': 'application/json'},
      body: jsonEncode({
        "token": currentToken,
        "refreshToken": currentRefresh,
        "deviceId": deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // الدخول قد يعود بـ token أو accessToken حسب إصدار الـ API
      final newToken = data['accessToken'] ?? data['token'];
      final newRefresh = data['refreshToken'] ?? data['refreshToken']; // استباقاً لأي تغيير

      if (newToken != null && newRefresh != null) {
        await AuthStorage.updateTokens(newToken, newRefresh);
        return true;
      }
    } else {
      print('❌ Refresh Token API failed: ${response.statusCode}');
      print('❌ Body: ${response.body}');
    }
    return false;
  } catch (e) {
    print('❌ Exception during refresh: $e');
    return false;
  }
}
