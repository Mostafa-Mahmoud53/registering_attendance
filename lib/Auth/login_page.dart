// login_page.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'colors.dart';
import 'api_service.dart';
import 'auth_widgets.dart';
import '../core/network/app_exception.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSwitchToActivation;
  final String deviceId;
  final Function(String) onDeviceIdRefresh;
  final Function(Map<String, dynamic>) onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onSwitchToActivation,
    required this.deviceId,
    required this.onDeviceIdRefresh,
    required this.onLoginSuccess,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // التحقق من صحة البريد الإلكتروني
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.emailIsRequired;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return AppLocalizations.of(context)!.enterValidEmail;
    }
    return null;
  }

  // التحقق من صحة كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.passwordIsRequired;
    }
    return null;
  }

  // Login function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      AuthWidgets.showWarningSnackBar(context, AppLocalizations.of(context)!.pleaseFixErrorsForm);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
        deviceId: widget.deviceId,
      );

      setState(() {
        _isLoading = false;
      });

      if (response['statusCode'] == 200) {
        final data = jsonDecode(response['body']);

        if (data['isSuccess'] == true) {
          final role = data['role'] ?? '';
          
          bool isDesktopPlatform = false;
          if (kIsWeb) {
            isDesktopPlatform = true;
          } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            isDesktopPlatform = true;
          }

          if (role == 'Student' && isDesktopPlatform) {
            _showInfoDialog('Access Denied', 'Student cannot login on the desktop version, and there is a mobile version he can use to login. Download it here: [APK_LINK]');
            return;
          }

          AuthWidgets.showSuccessSnackBar(context, AppLocalizations.of(context)!.loginSuccessful);

          // Pass user data to parent
          widget.onLoginSuccess({
            'token': data['token'] ?? '',
            'refreshToken': data['refreshToken'] ?? '',
            'role': role,
            'userName': data['userName'] ?? '',
            'email': _emailController.text,
            'deviceId': widget.deviceId,
          });
        } else {
          String errMsg = AppLocalizations.of(context)!.loginFailed;
          if (data['message'] != null && data['message'].toString().isNotEmpty) {
            errMsg = data['message'].toString();
          } else if (data['title'] != null && data['title'].toString().isNotEmpty) {
            errMsg = data['title'].toString();
          }
          AuthWidgets.showErrorSnackBar(
            context,
            AppException(
              message: errMsg,
            ),
          );
        }
      } else {
        final loc = AppLocalizations.of(context)!;
        int statusCode = response['statusCode'] as int;
        String errMsg = ApiService.loginErrorMessage(statusCode);

        AuthWidgets.showErrorSnackBar(
          context,
          AppException(message: errMsg),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AuthWidgets.showErrorSnackBar(
        context,
        AppException(message: AppLocalizations.of(context)!.somethingWentWrong),
      );
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: const TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              AppLocalizations.of(context)!.login,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              AppLocalizations.of(context)!.enterYourDetails,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Login email field
          AuthWidgets.buildTextField(
            controller: _emailController,
            label: AppLocalizations.of(context)!.email,
            hint: AppLocalizations.of(context)!.enterEmail,
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            validator: _validateEmail,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocus);
            },
          ),
          const SizedBox(height: 15),

          // Login password field
          AuthWidgets.buildPasswordField(
            controller: _passwordController,
            label: AppLocalizations.of(context)!.password,
            hint: AppLocalizations.of(context)!.enterPassword,
            obscureText: _obscurePassword,
            focusNode: _passwordFocus,
            validator: _validatePassword,
            onToggle: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          const SizedBox(height: 20),

          // Device ID display hidden from UI
          // AuthWidgets.buildDeviceIdDisplay(
          //     deviceId: widget.deviceId,
          //     onRefresh: () => widget.onDeviceIdRefresh('')
          // ),

          const SizedBox(height: 10),

          // Login button
          AuthWidgets.buildActionButton(
            text: AppLocalizations.of(context)!.login,
            onPressed: _login,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 15),

          // Switch to activation link
          Center(
            child: TextButton(
              onPressed: widget.onSwitchToActivation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dontHaveAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.activateAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
