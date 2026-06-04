import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';
import '../widgets/AppInstructionsCard.dart';

class CourseEnrollmentPage extends StatefulWidget {
  final String? initialCourseId;
  final bool isTab;
  const CourseEnrollmentPage({Key? key, this.initialCourseId, this.isTab = false}) : super(key: key);

  @override
  _CourseEnrollmentPageState createState() => _CourseEnrollmentPageState();
}

class _CourseEnrollmentPageState extends State<CourseEnrollmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseIdController;
  final TextEditingController _studentCodeController = TextEditingController();

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _authToken;

  static const String _apiUrl = 'http://77.83.242.94:5000/api/Course/enroll';

  @override
  void initState() {
    super.initState();
    _courseIdController = TextEditingController(text: widget.initialCourseId);
    _loadAuthToken();
  }

  @override
  void dispose() {
    _courseIdController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
  }

  String? _validateCourseId(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.emailIsRequired;
    }
    final courseId = int.tryParse(value);
    if (courseId == null || courseId <= 0) {
      return 'Please enter a valid Course ID number';
    }
    return null;
  }

  String? _validateStudentCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Student University Code is required';
    }
    if (value.length < 3) {
      return 'Code must be at least 3 characters';
    }
    return null;
  }

  Future<void> _enrollStudent() async {
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
      _apiResponse = null;
      _isSuccess = false;
    });

    try {
      // تحويل الـ courseId إلى integer
      final courseId = int.parse(_courseIdController.text.trim());

      // إعداد البيانات المطلوبة فقط
      final enrollmentData = {
        "courseId": courseId,
        "studentUniversityCode": _studentCodeController.text.trim(),
      };

      // استدعاء الـ API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(enrollmentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiResponse = responseData['message'] ?? 'Student enrolled successfully!';
          _isSuccess = true;
        });

        // تنظيف الحقول بعد النجاح
        _courseIdController.clear();
        _studentCodeController.clear();

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
        throw Exception(_enrollmentErrorMessage(response.statusCode));
      }
    } catch (e) {
      setState(() {
        _apiResponse = _safeErrorText(e);
        _isSuccess = false;
      });

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

  String _enrollmentErrorMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Student is already enrolled in this course.';
    }
    if (statusCode == 401) {
      return ApiService.sessionExpiredMessage;
    }
    if (statusCode == 403) {
      return "You don't have permission to do this.";
    }
    if (statusCode == 404) {
      return 'Course not found.';
    }
    if (statusCode == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return ApiService.serverErrorMessage;
    }
    return 'Invalid request. Please check your input and try again.';
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
          if (!widget.isTab)
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
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(
                    AppLocalizations.of(context)!.courseEnrollmentPage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.darkColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppInstructionsCard(
                    title: 'How to Enroll a Student',
                    instructions: [
                      'Obtain the student\'s exact University Code.',
                      'Enter the detail into the field below.',
                      'Click "Enroll Student" to finalize the registration.',
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Student University Code Field
                        _buildTextField(
                          controller: _studentCodeController,
                          label: AppLocalizations.of(context)!.studentUniversityCode,
                          hint: AppLocalizations.of(context)!.universityCodeHint,
                          prefixIcon: Icons.badge,
                          validator: _validateStudentCode,
                        ),
                        const SizedBox(height: 32),


                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _enrollStudent,
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
                                const Icon(Icons.person_add_alt, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.enroll,
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

                        // API Response
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
                                color: _isSuccess ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSuccess ? Icons.check_circle : Icons.error,
                                  color: _isSuccess ? Colors.green : Colors.red,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
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
              fontSize: 16,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

