// activation_page.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'colors.dart';
import 'api_service.dart';
import 'auth_widgets.dart';
import '../core/network/app_exception.dart';

class ActivationPage extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  final String deviceId;
  final Function(String) onDeviceIdRefresh;

  const ActivationPage({
    super.key,
    required this.onSwitchToLogin,
    required this.deviceId,
    required this.onDeviceIdRefresh,
  });

  @override
  _ActivationPageState createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _message = '';
  final bool _isError = false;

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

  // التحقق من صحة كود الجامعة
  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.codeIsRequired;
    }
    if (value.length < 3) {
      return 'Code must be at least 3 characters';
    }
    return null;
  }

  // التحقق من صحة كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.passwordIsRequired;
    }
    if (value.length < 6) {
      return AppLocalizations.of(context)!.enterStrongPassword;
    }
    return null;
  }

  // Account activation function
  Future<void> _activateAccount() async {
    if (!_formKey.currentState!.validate()) {
      AuthWidgets.showWarningSnackBar(context, AppLocalizations.of(context)!.pleaseFixErrorsForm);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    bool isDesktopPlatform = false;
    if (kIsWeb) {
      isDesktopPlatform = true;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      isDesktopPlatform = true;
    }

    if (isDesktopPlatform) {
      AuthWidgets.showErrorSnackBar(
        context,
        AppException(message: 'Students cannot activate their account on the desktop version. Please use the mobile app.'),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.activateAccount(
        universityEmail: _emailController.text,
        universityCode: _codeController.text,
        newPassword: _passwordController.text,
        deviceId: widget.deviceId,
      );

      setState(() {
        _isLoading = false;
      });

      if (response['statusCode'] == 200) {
        final data = jsonDecode(response['body']);
        
        // Show success message
        AuthWidgets.showSuccessSnackBar(context, AppLocalizations.of(context)!.activationSuccessful);

        // Switch to login page automatically after a small delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onSwitchToLogin();
          }
        });

      } else {
        AuthWidgets.showErrorSnackBar(
          context,
          AppException(message: ApiService.activationErrorMessage(response['statusCode'] as int)),
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

  Widget _buildMessageContainer() {
    if (_message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isError ? AppColors.errorColor.withValues(alpha: 0.1) : AppColors.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isError ? AppColors.errorColor.withValues(alpha: 0.3) : AppColors.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isError ? Icons.error_outline : Icons.check_circle_outline,
            color: _isError ? AppColors.errorColor : AppColors.successColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(
                color: _isError ? AppColors.errorColor : AppColors.successColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
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
              AppLocalizations.of(context)!.activateAccount,
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
              AppLocalizations.of(context)!.enterDetailsToActivate,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // University Email field
          AuthWidgets.buildTextField(
            controller: _emailController,
            label: AppLocalizations.of(context)!.universityEmail,
            hint: AppLocalizations.of(context)!.enterUniversityEmail,
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            validator: _validateEmail,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_codeFocus);
            },
          ),
          const SizedBox(height: 15),

          // University Code field
          AuthWidgets.buildTextField(
            controller: _codeController,
            label: AppLocalizations.of(context)!.universityCode,
            hint: AppLocalizations.of(context)!.enterCode,
            prefixIcon: Icons.vpn_key,
            focusNode: _codeFocus,
            validator: _validateCode,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocus);
            },
          ),
          const SizedBox(height: 15),

          // New Password field
          AuthWidgets.buildPasswordField(
            controller: _passwordController,
            label: AppLocalizations.of(context)!.newPassword,
            hint: AppLocalizations.of(context)!.enterStrongPassword,
            obscureText: _obscurePassword,
            focusNode: _passwordFocus,
            validator: _validatePassword,
            onToggle: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          const SizedBox(height: 10),

          // Device ID display hidden from UI
          // AuthWidgets.buildDeviceIdDisplay(
          //     deviceId: widget.deviceId,
          //     onRefresh: () => widget.onDeviceIdRefresh('')
          // ),

          const SizedBox(height: 10),

          // Activate button
          AuthWidgets.buildActionButton(
            text: AppLocalizations.of(context)!.activateAccount,
            onPressed: _activateAccount,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 10),

          // Switch to login link
          Center(
            child: TextButton(
              onPressed: widget.onSwitchToLogin,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.alreadyHaveAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.login,
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

          // Message display
          _buildMessageContainer(),
        ],
      ),
    );
  }
}
