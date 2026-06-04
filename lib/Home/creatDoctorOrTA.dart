import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';
import '../core/responsive.dart';
import '../widgets/AppInstructionsCard.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDoctor = true; // true = دكتور, false = معيد
  String? _authToken;

  // الـ URLs للـ APIs
  static const String _doctorApiUrl = 'http://77.83.242.94:5000/api/Admin/create-doctor';
  static const String _taApiUrl = 'http://77.83.242.94:5000/api/Admin/create-TA';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.passwordIsRequired;
    }
    if (value.length < 6) {
      return AppLocalizations.of(context)!.enterStrongPassword;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Authentication token not found'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // إعداد البيانات كما في الـ curl
      final userData = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      // اختيار الـ URL المناسب بناءً على نوع الحساب
      final apiUrl = _isDoctor ? _doctorApiUrl : _taApiUrl;

      // استدعاء الـ API المناسب
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ??
            (_isDoctor ? AppLocalizations.of(context)!.doctorAccountCreatedSuccessfully : AppLocalizations.of(context)!.taAccountCreatedSuccessfully);
        final accountId = responseData['${_isDoctor ? 'doctorId' : 'taId'}']?.toString();

        // عرض رسالة النجاح مع خيار الخروج
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message ${accountId != null ? '(ID: $accountId)' : ''}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Exit',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // تنظيف الحقول بعد النجاح
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();

        // الخروج التلقائي بعد 3 ثواني
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });

      } else {
        final message = ApiService.createDoctorTaErrorMessage(response.statusCode);
        throw Exception(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_safeErrorText(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  String _safeErrorText(Object error) {
    final text = error.toString().replaceAll('Exception: ', '');
    return text.isEmpty ? 'Something went wrong. Please try again.' : text;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: _isDoctor ? AppColors.primaryColor : Colors.orange,
            elevation: 8,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: Responsive.isDesktop(context),
              titlePadding: Responsive.isDesktop(context) 
                  ? const EdgeInsets.only(bottom: 20) 
                  : const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(
                    _isDoctor ? AppLocalizations.of(context)!.createDoctorAccount : AppLocalizations.of(context)!.createTAAccount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.isDesktop(context) ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _isDoctor ? AppColors.primaryColor : Colors.orange,
                      _isDoctor ? AppColors.darkColor : Colors.deepOrange,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 850 : 700),
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      AppLocalizations.of(context)!.createNewAccount,
                      style: TextStyle(
                        fontSize: Responsive.isDesktop(context) ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.fillDetailsToCreate,
                      style: TextStyle(
                        fontSize: Responsive.isDesktop(context) ? 16 : 14,
                        color: AppColors.darkColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    AppInstructionsCard(
                      title: AppLocalizations.of(context)!.accountCreationSteps,
                      instructions: [
                        AppLocalizations.of(context)!.selectAccountType,
                        AppLocalizations.of(context)!.enterFullName,
                        AppLocalizations.of(context)!.provideValidEmail,
                        AppLocalizations.of(context)!.setSecurePassword,
                        AppLocalizations.of(context)!.clickCreateButton,
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Account Type Toggle
                    _buildAccountTypeToggle(),
                    const SizedBox(height: 32),

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: AppLocalizations.of(context)!.fullName,
                      hint: _isDoctor ? AppLocalizations.of(context)!.enterDoctorName : AppLocalizations.of(context)!.enterTAName,
                      prefixIcon: Icons.person,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: AppLocalizations.of(context)!.emailAddress,
                      hint: AppLocalizations.of(context)!.emailAddress,
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter password (min 6 characters)',
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirements(),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDoctor ? AppColors.primaryColor : Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          '${AppLocalizations.of(context)!.create} ${_isDoctor ? AppLocalizations.of(context)!.doctor : AppLocalizations.of(context)!.teachingAssistant} ${AppLocalizations.of(context)!.createAccount.split(' ')[1]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.darkColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: AppColors.darkColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDoctor = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isDoctor ? AppColors.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDoctor ? Colors.transparent : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: _isDoctor ? Colors.white : AppColors.darkColor.withOpacity(0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.doctor,
                        style: TextStyle(
                          color: _isDoctor ? Colors.white : AppColors.darkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Teaching Assistant Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDoctor = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: !_isDoctor ? Colors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isDoctor ? Colors.transparent : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school,
                        color: !_isDoctor ? Colors.white : AppColors.darkColor.withOpacity(0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.teachingAssistant,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isDoctor ? Colors.white : AppColors.darkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.isDesktop(context) ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.darkColor.withOpacity(0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDoctor ? AppColors.primaryColor : Colors.orange,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                prefixIcon,
                color: AppColors.darkColor.withOpacity(0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: AppColors.darkColor,
              fontSize: Responsive.isDesktop(context) ? 18 : 16,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required String? Function(String?)? validator,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.isDesktop(context) ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.darkColor.withOpacity(0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDoctor ? AppColors.primaryColor : Colors.orange,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.lock,
                color: AppColors.darkColor.withOpacity(0.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.darkColor.withOpacity(0.5),
                ),
                onPressed: onToggle,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: AppColors.darkColor,
              fontSize: Responsive.isDesktop(context) ? 18 : 16,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.passwordReqs,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.successColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.atLeast6Chars,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

