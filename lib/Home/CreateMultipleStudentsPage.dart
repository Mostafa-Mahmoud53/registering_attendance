import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../widgets/app_instructions_card.dart';
import '../core/responsive.dart';

class CreateMultipleStudentsPage extends StatefulWidget {
  final bool isTab;
  const CreateMultipleStudentsPage({super.key, this.isTab = false});

  @override
  _CreateMultipleStudentsPageState createState() => _CreateMultipleStudentsPageState();
}

class _CreateMultipleStudentsPageState extends State<CreateMultipleStudentsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final List<Map<String, String>> _studentsList = [];

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _authToken;

  static const String _apiUrl = 'http://77.83.242.94:5000/api/Admin/create-students-bulk';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.emailIsRequired;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return AppLocalizations.of(context)!.enterValidEmail;
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) return 'University code is required';
    return null;
  }

  void _addStudent() {
    if (_validateName(_nameController.text) != null ||
        _validateEmail(_emailController.text) != null ||
        _validateCode(_codeController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all errors before adding'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _studentsList.add({
        'name': _nameController.text.trim(),
        'universityEmail': _emailController.text.trim(),
        'universityCode': _codeController.text.trim(),
      });
      _nameController.clear();
      _emailController.clear();
      _codeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student added to list'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeStudent(int index) {
    setState(() {
      _studentsList.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _studentsList.clear();
      _nameController.clear();
      _emailController.clear();
      _codeController.clear();
      _apiResponse = null;
      _isSuccess = false;
    });
  }

  Future<void> _submitMultipleStudents() async {
    if (_studentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one student'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _apiResponse = null;
      _isSuccess = false;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_studentsList),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiResponse = responseData['message'] ?? 'Students created successfully!';
          _isSuccess = true;
          _studentsList.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_apiResponse!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to create students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: ${e.toString().replaceAll("Exception: ", "")}';
        _isSuccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiResponse!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(
        slivers: [
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
              flexibleSpace: FlexibleSpaceBar(
                title: Text(AppLocalizations.of(context)!.createMultiple, style: const TextStyle(color: Colors.white, fontSize: 18)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryColor, AppColors.darkColor]),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppInstructionsCard(
                    title: 'How to Create Multiple Students',
                    instructions: [
                      AppLocalizations.of(context)!.createOption2,
                      AppLocalizations.of(context)!.createOption3,
                      AppLocalizations.of(context)!.createOption4,
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_apiResponse != null) _buildApiResponseCard(),
                  const SizedBox(height: 16),
                  
                  _buildAddStudentForm(),
                  const SizedBox(height: 24),

                  if (_studentsList.isNotEmpty) ...[
                    _buildStudentsListCard(),
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: Responsive.isDesktop(context) ? 400 : double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitMultipleStudents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(AppLocalizations.of(context)!.addBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStudentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
          const SizedBox(height: 16),
          _buildFormField(controller: _nameController, label: 'Student Name', hint: 'Enter student full name', prefixIcon: Icons.person, validator: _validateName),
          const SizedBox(height: 16),
          _buildFormField(controller: _emailController, label: 'University Email', hint: 'Enter university email', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
          const SizedBox(height: 16),
          _buildFormField(controller: _codeController, label: 'University Code', hint: 'Enter university code', prefixIcon: Icons.badge, validator: _validateCode),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.errorColor),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(AppLocalizations.of(context)!.clearBtn, style: const TextStyle(color: Colors.blue))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required TextEditingController controller, required String label, required String hint, required IconData prefixIcon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.darkColor.withValues(alpha: 0.4)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.errorColor, width: 1.5)),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(prefixIcon, color: AppColors.darkColor.withValues(alpha: 0.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(color: AppColors.darkColor, fontSize: 16),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsListCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Students to Add (${_studentsList.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successColor),
                ),
                child: Text('Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentsList.length,
            itemBuilder: (context, index) {
              final student = _studentsList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightColor2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student['name']!, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkColor)),
                          Text('${student['universityCode']} | ${student['universityEmail']}', style: TextStyle(fontSize: 12, color: AppColors.darkColor.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeStudent(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiResponseCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(_isSuccess ? Icons.check_circle : Icons.error, color: _isSuccess ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_apiResponse!, style: TextStyle(color: AppColors.darkColor, fontSize: 14))),
        ],
      ),
    );
  }
}
