import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/api_service.dart';
import '../Auth/colors.dart';
import '../core/responsive.dart';
import '../l10n/app_localizations.dart';
import '../widgets/AppInstructionsCard.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({Key? key}) : super(key: key);

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _doctorCodeController = TextEditingController();

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _authToken;

  static const String _apiUrl =
      'http://msngroup-001-site1.ktempurl.com/api/Admin/create-course';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _doctorCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
  }

  String? _validateName(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) return loc.courseNameIsRequired;
    if (value.length < 2) return loc.courseNameMustBeAtLeast2Chars;
    return null;
  }

  String? _validateCode(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) return loc.courseCodeIsRequired;
    if (value.length < 2) return loc.courseCodeMustBeAtLeast2Chars;
    return null;
  }

  String? _validateDescription(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) return loc.courseDescriptionIsRequired;
    if (value.length < 5) return loc.courseDescriptionMustBeAtLeast5Chars;
    return null;
  }

  String? _validateDoctorCode(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.doctorUniversityCodeIsRequired;
    }
    if (value.trim().length < 2) {
      return loc.doctorUniversityCodeMustBeValid;
    }
    return null;
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.authenticationTokenNotFound),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _apiResponse = null;
      _isSuccess = false;
    });

    try {
      final courseData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'courseCode': _codeController.text.trim(),
        'doctorUniversityCode': _doctorCodeController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(courseData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiResponse = responseData['message'] ?? loc.courseCreatedSuccessfully;
          _isSuccess = true;
        });

        _nameController.clear();
        _codeController.clear();
        _descriptionController.clear();
        _doctorCodeController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_apiResponse!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception(ApiService.createCourseErrorMessage(response.statusCode));
      }
    } catch (e) {
      setState(() {
        _apiResponse = _safeErrorText(e);
        _isSuccess = false;
      });

      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _safeErrorText(Object error) {
    final loc = AppLocalizations.of(context)!;
    final text = error.toString().replaceAll('Exception: ', '');
    return text.isEmpty ? loc.somethingWentWrong : text;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppColors.primaryColor,
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
                loc.createCourse,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.isDesktop(context) ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryColor, AppColors.darkColor],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.isDesktop(context) ? 850 : 700,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.lightColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.createCourse,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isArabic
                                        ? 'املأ جميع الحقول المطلوبة لإنشاء مقرر جديد'
                                        : 'Fill in all required fields to create a new course',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.darkColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppInstructionsCard(
                        title: isArabic ? 'خطوات إنشاء المقرر' : 'Course Creation Steps',
                        instructions: [
                          isArabic
                              ? 'أدخل اسمًا واضحًا ووصفيًا للمقرر.'
                              : 'Enter a clear, descriptive name for the course.',
                          isArabic
                              ? 'وفر كود مقرر فريدًا (مثال: CS4710).'
                              : 'Provide a unique Course Code (e.g., CS4710).',
                          isArabic
                              ? 'أدخل كود الجامعة الصحيح للعضو المسؤول عن هذا المقرر.'
                              : 'Enter the exact University Code of the Doctor assigned to this course.',
                          isArabic
                              ? 'أضف وصفًا مختصرًا لمحتوى المقرر.'
                              : 'Provide a brief description of the course contents.',
                          isArabic
                              ? 'اضغط "إنشاء مقرر" لإتمام العملية.'
                              : 'Click "Create Course" to finalize.',
                        ],
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: loc.courseName,
                              hint: loc.enterCourseName,
                              prefixIcon: Icons.book,
                              validator: _validateName,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _codeController,
                              label: loc.courseCode,
                              hint: loc.enterCourseCode,
                              prefixIcon: Icons.code,
                              validator: _validateCode,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _doctorCodeController,
                              label: isArabic ? 'كود الأستاذ الجامعي' : 'Doctor University Code',
                              hint: isArabic
                                  ? 'أدخل كود الأستاذ الجامعي (مثال: DR-1234)'
                                  : 'Enter doctor university code (e.g., DR-1234)',
                              prefixIcon: Icons.badge,
                              keyboardType: TextInputType.text,
                              validator: _validateDoctorCode,
                            ),
                            const SizedBox(height: 24),
                            _buildDescriptionField(loc),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
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
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_circle, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            loc.createCourse,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_apiResponse != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: _isSuccess
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _isSuccess ? Colors.green : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isSuccess
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: _isSuccess
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _apiResponse!,
                                        style: TextStyle(
                                          color: AppColors.darkColor,
                                          fontSize: 14,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!_isSuccess)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _apiResponse = null;
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(left: 8),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.isDesktop(context) ? 16 : 14,
                fontWeight: FontWeight.w600,
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
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
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
                      color: AppColors.primaryColor,
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
      },
    );
  }

  Widget _buildDescriptionField(AppLocalizations loc) {
    return Builder(
      builder: (context) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.courseDescription,
              style: TextStyle(
                fontSize: Responsive.isDesktop(context) ? 16 : 14,
                fontWeight: FontWeight.w600,
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
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'أدخل وصف المقرر'
                      : 'Enter course description',
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
                      color: AppColors.primaryColor,
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
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: AppColors.darkColor,
                  fontSize: Responsive.isDesktop(context) ? 18 : 16,
                ),
                validator: _validateDescription,
              ),
            ),
          ],
        );
      },
    );
  }
}