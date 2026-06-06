import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../widgets/app_instructions_card.dart';
import '../core/responsive.dart';

class CreateExcelStudentsPage extends StatefulWidget {
  final bool isTab;
  const CreateExcelStudentsPage({super.key, this.isTab = false});

  @override
  _CreateExcelStudentsPageState createState() => _CreateExcelStudentsPageState();
}

class _CreateExcelStudentsPageState extends State<CreateExcelStudentsPage> {
  final List<Map<String, String>> _studentsList = [];

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _authToken;

  bool _isImporting = false;
  String? _importMessage;
  List<String> _importErrors = [];

  static const String _apiUrl = 'http://77.83.242.94:5000/api/Admin/create-students-bulk';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
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
      if (path == null) throw Exception('Selected file is not available.');

      final bytes = File(path).readAsBytesSync();
      final workbook = excel.Excel.decodeBytes(bytes);
      if (workbook.tables.isEmpty) throw Exception('No sheets found in the Excel file.');

      final sheet = workbook.tables.values.first;
      if (sheet.rows.isEmpty) throw Exception('The Excel sheet is empty.');

      final headerRow = sheet.rows.first;
      final headerMap = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        final key = _normalizeHeader(headerRow[i]?.value);
        if (key.isNotEmpty) headerMap[key] = i;
      }

      final nameIndex = _findHeaderIndex(headerMap, ['name', 'student name', 'full name']);
      final emailIndex = _findHeaderIndex(headerMap, ['university email', 'email', 'student email']);
      final codeIndex = _findHeaderIndex(headerMap, ['university code', 'code', 'student code']);

      if (nameIndex == null || emailIndex == null || codeIndex == null) {
        throw Exception('Missing required headers. Use: name, universityEmail, universityCode.');
      }

      int added = 0;
      int skipped = 0;
      final errors = <String>[];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = _cellValue(row, nameIndex);
        final email = _cellValue(row, emailIndex);
        final code = _cellValue(row, codeIndex);

        if (name.isEmpty && email.isEmpty && code.isEmpty) continue;

        if (name.length < 2 || email.isEmpty || code.isEmpty) {
          skipped++;
          errors.add('Row ${i + 1}: Invalid data');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_importMessage!), backgroundColor: AppColors.successColor, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      setState(() {
        _importMessage = 'Import failed: ${e.toString()}';
        _importErrors = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_importMessage!), backgroundColor: AppColors.errorColor, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _clearAll() {
    setState(() {
      _studentsList.clear();
      _apiResponse = null;
      _isSuccess = false;
      _importMessage = null;
      _importErrors = [];
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
          _importMessage = null;
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
                title: Text(AppLocalizations.of(context)!.excelSheet, style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                    title: 'How to Create Students via Excel',
                    instructions: [
                      AppLocalizations.of(context)!.createOption1,
                      AppLocalizations.of(context)!.createOption3,
                      AppLocalizations.of(context)!.createOption4,
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_apiResponse != null) _buildApiResponseCard(),
                  const SizedBox(height: 16),
                  
                  _buildImportCard(),
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

  Widget _buildImportCard() {
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
          Text(AppLocalizations.of(context)!.importFromExcel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.uploadExcelCreateHint, style: TextStyle(fontSize: 13, color: AppColors.darkColor.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importStudentsFromExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isImporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(_isImporting ? AppLocalizations.of(context)!.importing : AppLocalizations.of(context)!.uploadExcel, style: const TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isImporting ? null : _clearAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(AppLocalizations.of(context)!.clearAll)),
                ),
              ),
            ],
          ),
          if (_importMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_importErrors.isEmpty ? Icons.check_circle : Icons.warning_amber, color: _importErrors.isEmpty ? AppColors.successColor : AppColors.warningColor, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_importMessage!, style: TextStyle(fontSize: 13, color: AppColors.darkColor, fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ],
      ),
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
