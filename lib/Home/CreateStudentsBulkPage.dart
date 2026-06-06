// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../widgets/app_instructions_card.dart';
import '../core/responsive.dart';

class CreateStudentsBulkPage extends StatefulWidget {
  const CreateStudentsBulkPage({super.key});

  @override
  _CreateStudentsBulkPageState createState() => _CreateStudentsBulkPageState();
}

class _CreateStudentsBulkPageState extends State<CreateStudentsBulkPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _studentsDataController = TextEditingController();

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _authToken;
  Map<String, dynamic>? _apiResult;
  bool _isImporting = false;
  String? _importMessage;
  List<String> _importErrors = [];

  static const String _apiUrl =
      'http://77.83.242.94:5000/api/Admin/create-students-bulk';

  // قائمة للطلاب الذين سيتم إضافتهم
  final List<Map<String, String>> _studentsList = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

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
    _studentsDataController.dispose();
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
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
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

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'University code is required';
    }
    return null;
  }

  void _addStudent() {
    if (_validateName(_nameController.text) != null ||
        _validateEmail(_emailController.text) != null ||
        _validateCode(_codeController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix all errors before adding'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final student = {
      'name': _nameController.text.trim(),
      'universityEmail': _emailController.text.trim(),
      'universityCode': _codeController.text.trim(),
    };

    setState(() {
      _studentsList.add(student);
      _nameController.clear();
      _emailController.clear();
      _codeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Student added to list'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
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
      _apiResult = null;
      _importMessage = null;
      _importErrors = [];
    });
  }

  String _normalizeHeader(dynamic value) {
    if (value == null) return '';
    return value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int? _findHeaderIndex(Map<String, int> headers, List<String> candidates) {
    for (final key in candidates) {
      final normalized = _normalizeHeader(key);
      if (headers.containsKey(normalized)) return headers[normalized];
    }
    return null;
  }

  String _cellValue(List<excel.Data?> row, int? index) {
    if (index == null || index >= row.length) return '';
    final cell = row[index];
    final value = cell?.value;
    return value?.toString().trim() ?? '';
  }

  Future<void> _importStudentsFromExcel() async {
    if (_isImporting) return;
    setState(() {
      _isImporting = true;
      _importMessage = null;
      _importErrors = [];
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        setState(() => _isImporting = false);
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        throw Exception('Selected file is not available.');
      }

      final bytes = File(path).readAsBytesSync();
      final workbook = excel.Excel.decodeBytes(bytes);
      if (workbook.tables.isEmpty) {
        throw Exception('No sheets found in the Excel file.');
      }

      final sheet = workbook.tables.values.first;
      if (sheet.rows.isEmpty) {
        throw Exception('The Excel sheet is empty.');
      }

      final headerRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        final key = _normalizeHeader(headerRow[i]?.value);
        if (key.isNotEmpty) headerMap[key] = i;
      }

      final nameIndex = _findHeaderIndex(headerMap, [
        'name',
        'student name',
        'full name',
      ]);
      final emailIndex = _findHeaderIndex(headerMap, [
        'university email',
        'email',
        'student email',
      ]);
      final codeIndex = _findHeaderIndex(headerMap, [
        'university code',
        'code',
        'student code',
      ]);

      if (nameIndex == null || emailIndex == null || codeIndex == null) {
        throw Exception(
          'Missing required headers. Use: name, universityEmail, universityCode.',
        );
      }

      int added = 0;
      int skipped = 0;
      final errors = <String>[];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = _cellValue(row, nameIndex);
        final email = _cellValue(row, emailIndex);
        final code = _cellValue(row, codeIndex);

        if (name.isEmpty && email.isEmpty && code.isEmpty) {
          continue;
        }

        final nameError = _validateName(name);
        final emailError = _validateEmail(email);
        final codeError = _validateCode(code);

        if (nameError != null || emailError != null || codeError != null) {
          skipped++;
          errors.add('Row ${i + 1}: ${nameError ?? emailError ?? codeError}');
          continue;
        }

        _studentsList.add({
          'name': name,
          'universityEmail': email,
          'universityCode': code,
        });
        added++;
      }

      setState(() {
        _importMessage = 'Imported $added students, skipped $skipped rows.';
        _importErrors = errors;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_importMessage ?? 'Import completed'),
          backgroundColor: AppColors.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _importMessage = 'Import failed: ${e.toString()}';
        _importErrors = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_importMessage ?? 'Import failed'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (_studentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one student'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      _apiResult = null;
    });

    try {
      // تحويل القائمة إلى JSON
      final studentsData = _studentsList;

      print('Sending ${_studentsList.length} students to API');

      // استدعاء الـ API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(studentsData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiResult = responseData;
          _apiResponse =
              responseData['message'] ?? 'Students created successfully!';
          _isSuccess = true;
        });

        // عرض رسالة النجاح
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
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Bad request: ${response.statusCode}',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token may be expired');
      } else {
        throw Exception('Failed to create students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: ${e.toString()}';
        _isSuccess = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1400 : 800),
          child: CustomScrollView(
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
                    AppLocalizations.of(context)!.bulkCreateStudents,
                    style: TextStyle(
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
                    colors: [AppColors.primaryColor, AppColors.darkColor],
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
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group_add,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.createMultipleStudents,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.addStudentsBulkSubtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  AppInstructionsCard(
                    title: AppLocalizations.of(context)!.howToCreateStudents,
                    instructions: [
                      AppLocalizations.of(context)!.createOption1,
                      AppLocalizations.of(context)!.createOption2,
                      AppLocalizations.of(context)!.createOption3,
                      AppLocalizations.of(context)!.createOption4,
                    ],
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  
                  // API Response
                  if (_apiResponse != null) _buildApiResponseCard(),
                  
                  _buildImportCard(),
                  const SizedBox(height: 16),
                  _buildAddStudentForm(),
                  const SizedBox(height: 24),

                  // Students List
                  if (_studentsList.isNotEmpty) ...[
                    _buildStudentsListCard(),
                    const SizedBox(height: 32),
                  ],

                  // Submit Button
                  if (_studentsList.isNotEmpty) ...[
                    Center(
                      child: SizedBox(
                        width: Responsive.isDesktop(context) ? 400 : double.infinity,
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
        ),
      ),
    );
  }

  Widget _buildAddStudentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Student',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkColor,
            ),
          ),
          const SizedBox(height: 16),

          // Name Field
          _buildFormField(
            controller: _nameController,
            label: 'Student Name',
            hint: 'Enter student full name',
            prefixIcon: Icons.person,
            validator: _validateName,
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildFormField(
            controller: _emailController,
            label: 'University Email',
            hint: 'Enter university email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),

          // Code Field
          _buildFormField(
            controller: _codeController,
            label: 'University Code',
            hint: 'Enter university code',
            prefixIcon: Icons.badge,
            keyboardType: TextInputType.text,
            validator: _validateCode,
          ),
          const SizedBox(height: 24),

          // Add Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.errorColor),
                  ),
                  child: Text(AppLocalizations.of(context)!.clearBtn, style: const TextStyle(color: Colors.blue)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
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
                color: Colors.grey.withValues(alpha: 0.08),
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
              hintStyle: TextStyle(color: AppColors.darkColor.withValues(alpha: 0.4)),
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
                borderSide: BorderSide(color: AppColors.errorColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                prefixIcon,
                color: AppColors.darkColor.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students to Add (${_studentsList.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successColor),
                ),
                child: Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Students List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentsList.length,
            itemBuilder: (context, index) {
              final student = _studentsList[index];
              return _buildStudentListItem(student, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.importFromExcel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.uploadExcelCreateHint,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importStudentsFromExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    AppLocalizations.of(context)!.uploadExcel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isImporting
                    ? null
                    : () {
                        setState(() {
                          _importMessage = null;
                          _importErrors = [];
                        });
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Clear')  ,
              ),
            ],
          ),
          if (_importMessage != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _importErrors.isEmpty
                      ? Icons.check_circle
                      : Icons.warning_amber,
                  color: _importErrors.isEmpty
                      ? AppColors.successColor
                      : AppColors.warningColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_importErrors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _importErrors.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.errorColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_importErrors.length > 5) ...[
              const SizedBox(height: 6),
              Text(
                '...and ${_importErrors.length - 5} more errors',
                style: TextStyle(fontSize: 12, color: AppColors.errorColor),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStudentListItem(Map<String, String> student, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightColor2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: AppColors.darkColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        student['universityEmail']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkColor.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      size: 14,
                      color: AppColors.darkColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      student['universityCode']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.errorColor, size: 20),
            onPressed: () => _removeStudent(index),
          ),
        ],
      ),
    );
  }

  Widget _buildApiResponseCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_apiResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultItem(
                    'Total Students',
                    _apiResult!['totalRequested']?.toString() ?? '0',
                    AppColors.primaryColor,
                  ),
                  _buildResultItem(
                    'Successfully Created',
                    _apiResult!['createdCount']?.toString() ?? '0',
                    Colors.green,
                  ),
                  _buildResultItem(
                    'Skipped',
                    _apiResult!['skippedCount']?.toString() ?? '0',
                    Colors.orange,
                  ),
                  if (_apiResult!['skippedCodes'] != null &&
                      (_apiResult!['skippedCodes'] as List).isNotEmpty)
                    _buildResultItem(
                      'Skipped Codes',
                      (_apiResult!['skippedCodes'] as List).join(', '),
                      Colors.red,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
