import 'dart:convert';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../../Auth/api_service.dart';
import '../../Auth/auth_storage.dart';
import '../../core/network/app_exception.dart';
import 'session_models.dart';

class SessionService {
  static const String baseUrl = 'http://77.83.242.94:5000/api';

  Future<String> _getToken() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    throw Exception('Authentication token not found');
  }

  Future<CreateSessionResponse> createSession(CreateSessionDto dto) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/Session/create');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return CreateSessionResponse.fromJson(decoded);
      } else {
        throw const AppException(
          message: 'A conflicting session already exists for this course.',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(message: 'Something went wrong. Please try again.');
    }
  }

  Future<RotateQrResponse> rotateQr(int sessionId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/Session/rotateqr/$sessionId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RotateQrResponse.fromJson(jsonDecode(response.body));
      } else {
        throw AppException(
          message: response.statusCode == 400
              ? 'This session is already stopped.'
              : response.statusCode == 403
                  ? "You don't have permission to do this."
                  : response.statusCode == 401
                      ? ApiService.sessionExpiredMessage
                      : ApiService.serverErrorMessage,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(message: 'Something went wrong. Please try again.');
    }
  }

  Future<void> stopSession(int sessionId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/Session/stop/$sessionId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          message: response.statusCode == 400
              ? 'This session is already stopped.'
              : response.statusCode == 403
                  ? "You don't have permission to do this."
                  : response.statusCode == 401
                      ? ApiService.sessionExpiredMessage
                      : ApiService.serverErrorMessage,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(message: 'Something went wrong. Please try again.');
    }
  }

  Future<CreateSessionResponse> resumeSession(int sessionId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/Session/resume/$sessionId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return CreateSessionResponse.fromJson(decoded);
      } else {
        throw AppException(
          message: response.statusCode == 400
              ? 'This session is already active.'
              : response.statusCode == 403
                  ? "You don't have permission to do this."
                  : response.statusCode == 401
                      ? ApiService.sessionExpiredMessage
                      : ApiService.serverErrorMessage,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(message: 'Something went wrong. Please try again.');
    }
  }

  Future<void> updateRadius(int sessionId, int radius) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/Session/updateradius/$sessionId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: radius.toString(), // Note: body as string "50"
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          message: response.statusCode == 403
              ? "You don't have permission to do this."
              : response.statusCode == 401
                  ? ApiService.sessionExpiredMessage
                  : response.statusCode == 400
                      ? 'Invalid request. Please check your input and try again.'
                      : ApiService.serverErrorMessage,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(message: 'Something went wrong. Please try again.');
    }
  }
}


