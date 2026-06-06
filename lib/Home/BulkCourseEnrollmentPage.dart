import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';
import '../widgets/app_instructions_card.dart';

class BulkCourseEnrollmentPage extends StatefulWidget {
  final String? initialCourseId;
  final bool isTab;
  const BulkCourseEnrollmentPage({super.key, this.initialCourseId, this.isTab = false});

  @override
  _BulkCourseEnrollmentPageState createState() => _BulkCourseEnrollmentPageState();
}

class _BulkCourseEnrollmentPageState extends State<BulkCourseEnrollmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseIdController;

  bool _isLoading = false;
  bool _isImporting = false;
  String? _importMessage;
  List<String> _importErrors = [];
  final List<String> _codesList = [];
  
  String? _authToken;

  static const String _apiUrl = 'http://77.83.242.94:5000/api/Course/enroll-bulk';

  @override
  void initState() {
    super.initState();
    _courseIdController = TextEditingController(text: widget.initialCourseId);
    _loadAuthToken();
  }

  @override
  void dispose() {
    _courseIdController.dispose();
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
      return 'Course ID is required';
    }
    final courseId = int.tryParse(value);
    if (courseId == null || courseId <= 0) {
      return 'Please enter a valid Course ID number';
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _normalizeHeader(dynamic v) =>
      v?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';

  int? _findHeaderIndex(Map<String, int> h, List<String> c) {
    for (final k in c) {
      final n = _normalizeHeader(k);
      if (h.containsKey(n)) return h[n];
    }
    return null;
  }

  String _cellValue(List<excel.Data?> row, int? idx) {
    if (idx == null || idx >= row.length) return '';
    return row[idx]?.value?.toString().trim() ?? '';
  }

  // ── Excel import ──────────────────────────────────────────────
  Future<void> _importFromExcel() async {
    if (_isImporting) return;
    setState(() { _isImporting = true; _importMessage = null; _importErrors = []; });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null) { setState(() => _isImporting = false); return; }

      final path = result.files.single.path;
      if (path == null) throw Exception('File not available.');

      final bytes = File(path).readAsBytesSync();
      final workbook = excel.Excel.decodeBytes(bytes);
      if (workbook.tables.isEmpty) throw Exception('No sheets found.');

      final sheet = workbook.tables.values.first;
      if (sheet.rows.isEmpty) throw Exception('Sheet is empty.');

      final headerRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        final k = _normalizeHeader(headerRow[i]?.value);
        if (k.isNotEmpty) headerMap[k] = i;
      }

      final codeIdx = _findHeaderIndex(headerMap,
          ['university code', 'universitycode', 'code', 'student code', 'studentcode']);
      if (codeIdx == null) throw Exception('Column "university code" or "code" not found.');

      int added = 0, skipped = 0;
      final errors = <String>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        final code = _cellValue(sheet.rows[i], codeIdx);
        if (code.isEmpty) continue;
        if (_codesList.contains(code)) {
          skipped++; errors.add('Row ${i+1}: duplicate "$code" skipped'); continue;
        }
        _codesList.add(code); added++;
      }
      setState(() {
        _importMessage = 'Imported $added codes, skipped $skipped rows.';
        _importErrors = errors;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Imported $added codes'), backgroundColor: AppColors.successColor));
    } catch (e) {
      setState(() { _importMessage = 'Import failed: $e'; _importErrors = []; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Import failed: $e'), backgroundColor: AppColors.errorColor));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _enrollStudentsBulk() async {
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

    if (_codesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one student code'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تحويل الـ courseId إلى integer
      final courseId = int.parse(_courseIdController.text.trim());

      // إعداد البيانات المطلوبة
      final enrollmentData = {
        "courseId": courseId,
        "studentCodes": _codesList,
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

      if (response.statusCode == 200 || response.statusCode == 207) {
        final responseData = jsonDecode(response.body);

        setState(() {
          _codesList.clear();
          _importMessage = null;
          _importErrors = [];
        });

        // Show the Result Dialog
        _showResultDialog(
          responseData['added'] != null ? List<String>.from(responseData['added']) : [],
          responseData['skipped'] != null ? List<String>.from(responseData['skipped']) : [],
          responseData['notFound'] != null ? List<String>.from(responseData['notFound']) : [],
          responseData['message'] ?? 'Enrollment process completed',
        );

      } else {
        throw Exception(_bulkEnrollmentErrorMessage(response.statusCode));
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

  String _bulkEnrollmentErrorMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
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
    return 'Something went wrong. Please try again.';
  }

  String _safeErrorText(Object error) {
    final text = error.toString().replaceAll('Exception: ', '');
    return text.isEmpty ? 'Something went wrong. Please try again.' : text;
  }

  void _showResultDialog(List<String> added, List<String> skipped, List<String> notFound, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.enrolledStudents, style: TextStyle(color: AppColors.darkColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty) Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (added.isNotEmpty) ...[
                  const Text('Added successfully:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: added.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.green.withValues(alpha: 0.2))).toList()),
                  const SizedBox(height: 10),
                ],
                if (skipped.isNotEmpty) ...[
                  const Text('Skipped (Already Enrolled):', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: skipped.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.orange.withValues(alpha: 0.2))).toList()),
                  const SizedBox(height: 10),
                ],
                if (notFound.isNotEmpty) ...[
                  const Text('Not Found:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: notFound.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12, color: Colors.white)), backgroundColor: Colors.red)).toList()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
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
              title: Row(
                children: [
                  const Text(
                    'Bulk Course Enrollment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                    title: 'How to Enroll Students via Excel',
                    instructions: [
                      'Enter the Course ID in the top field.',
                      'Use "Upload Excel" to select a .xlsx file containing a "University Code" column.',
                      'Review the compiled list of students below.',
                      'Click "Enroll Students" to finalize the registration.',
                      'A report will show which students were added, skipped, or not found.',
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Course ID Field
                        _buildTextField(
                          controller: _courseIdController,
                          label: 'Course ID',
                          hint: 'Enter course ID number',
                          prefixIcon: Icons.book,
                          keyboardType: TextInputType.number,
                          validator: _validateCourseId,
                        ),
                        const SizedBox(height: 24),
                        
                        _buildImportCard(),
                        const SizedBox(height: 16),
                        
                        if (_codesList.isNotEmpty) ...[
                          _buildCodesListCard(),
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _enrollStudentsBulk,
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
                                  const Icon(Icons.group_add, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Enroll ${_codesList.length} Student${_codesList.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
              hintStyle: TextStyle(
                color: AppColors.darkColor.withValues(alpha: 0.4),
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
                color: AppColors.darkColor.withValues(alpha: 0.5),
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

  Widget _buildImportCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Import From Excel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
      const SizedBox(height: 8),
      Text('Upload an Excel file with a column named "university code" or "code"',
          style: TextStyle(fontSize: 13, color: AppColors.darkColor.withValues(alpha: 0.6))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isImporting ? null : _importFromExcel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isImporting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.upload_file),
            label: Text(_isImporting ? 'Importing...' : 'Upload Excel',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _isImporting ? null : () => setState(() {
            _codesList.clear(); _importMessage = null; _importErrors = [];
          }),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const Text('Clear'),
        ),
      ]),
      if (_importMessage != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          Icon(_importErrors.isEmpty ? Icons.check_circle : Icons.warning_amber,
              color: _importErrors.isEmpty ? AppColors.successColor : AppColors.warningColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_importMessage!,
              style: TextStyle(fontSize: 13, color: AppColors.darkColor, fontWeight: FontWeight.w600))),
        ]),
      ],
      if (_importErrors.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _importErrors.take(5).map((e) =>
              Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text(e, style: TextStyle(fontSize: 12, color: AppColors.errorColor)))).toList(),
          ),
        ),
        if (_importErrors.length > 5)
          Text('...and ${_importErrors.length - 5} more errors',
              style: TextStyle(fontSize: 12, color: AppColors.errorColor)),
      ],
    ]),
  );

  Widget _buildCodesListCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Students to Enroll (${_codesList.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Text('Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
        ),
      ]),
      const SizedBox(height: 16),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _codesList.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightColor2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i+1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontSize: 12)))),
            const SizedBox(width: 12),
            Expanded(child: Text(_codesList[i],
                style: TextStyle(color: AppColors.darkColor, fontWeight: FontWeight.w500))),
            GestureDetector(
              onTap: () => setState(() => _codesList.removeAt(i)),
              child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
          ]),
        ),
      ),
    ]),
  );
}

