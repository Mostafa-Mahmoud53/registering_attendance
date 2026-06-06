import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../Auth/colors.dart';
import '../Auth/auth_storage.dart';
import '../Auth/api_service.dart';
import '../widgets/app_instructions_card.dart';

class DeleteExcelStudentsPage extends StatefulWidget {
  final bool isTab;
  const DeleteExcelStudentsPage({super.key, this.isTab = false});

  @override
  _DeleteExcelStudentsPageState createState() => _DeleteExcelStudentsPageState();
}

class _DeleteExcelStudentsPageState extends State<DeleteExcelStudentsPage> {
  bool _isLoading = false;
  bool _isImporting = false;
  String? _apiResponse;
  bool _isSuccess = false;
  String? _importMessage;
  List<String> _importErrors = [];
  final List<String> _codesList = [];

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
      _snack('✅ Imported $added codes', AppColors.successColor);
    } catch (e) {
      setState(() { _importMessage = 'Import failed: $e'; _importErrors = []; });
      _snack('Import failed: $e', AppColors.errorColor);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _clearAll() {
    setState(() {
      _codesList.clear(); _importMessage = null; _importErrors = [];
      _apiResponse = null; _isSuccess = false;
    });
  }

  Future<void> _deleteStudents() async {
    if (_codesList.isEmpty) { _snack('Add codes first', Colors.orange); return; }
    
    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      _snack('Authentication token not found', Colors.red);
      return;
    }

    final ok = await _showConfirm(
        'Delete ${_codesList.length} students?',
        'This permanently removes their accounts.\n⚠️ Cannot be undone!',
        'Delete ${_codesList.length} Students');
    if (!ok) return;

    if (!mounted) return;
    setState(() { _isLoading = true; _apiResponse = null; _isSuccess = false; });
    try {
      final response = await ApiService.bulkDeleteStudents(
        codes: _codesList,
        token: token,
      );
      
      final statusCode = response['statusCode'] as int;
      final responseBody = response['body'] as String;

      if (statusCode == 200) {
        final count = _codesList.length;
        String msg = '✅ $count student(s) deleted successfully!';
        try { final d = jsonDecode(responseBody); if (d['message'] != null) msg = '✅ ${d['message']}'; } catch (_) {}
        
        if (!mounted) return;
        setState(() { _apiResponse = msg; _isSuccess = true; });
        _codesList.clear();
        _importMessage = null; _importErrors = [];
        _snack('✅ $count student(s) deleted!', Colors.green);
      } else {
        String err = 'Failed ($statusCode)';
        try { err = jsonDecode(responseBody)['message'] ?? err; } catch (_) {}
        throw Exception(err);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _apiResponse = 'Error: $e'; _isSuccess = false; });
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating));
  }

  Future<bool> _showConfirm(String title, String body, String label) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.red))),
        ]),
        content: Text(body, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(label),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(slivers: [
        if (!widget.isTab)
          SliverAppBar(
            expandedHeight: 120, collapsedHeight: 80,
            pinned: true, floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppColors.errorColor, elevation: 8,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(AppLocalizations.of(context)!.excelSheet, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.errorColor, const Color(0xFFD65F51)])),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
              AppInstructionsCard(
                title: 'How to Delete Students via Excel',
                instructions: [
                  AppLocalizations.of(context)!.deleteOption1,
                  AppLocalizations.of(context)!.deleteOption3,
                  AppLocalizations.of(context)!.deleteOption4,
                  AppLocalizations.of(context)!.deleteOption5,
                ],
              ),
              const SizedBox(height: 16),

              if (_apiResponse != null) _buildResponseCard(),
              const SizedBox(height: 16),

              _buildImportCard(),
              const SizedBox(height: 16),

              if (_codesList.isNotEmpty) ...[
                _buildCodesListCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deleteStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Delete ${_codesList.length} Student${_codesList.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildResponseCard() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
    ),
    child: Row(children: [
      Icon(_isSuccess ? Icons.check_circle : Icons.error, color: _isSuccess ? Colors.green : Colors.red, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(_apiResponse!, style: TextStyle(color: AppColors.darkColor, fontSize: 14))),
      GestureDetector(onTap: () => setState(() => _apiResponse = null), child: const Icon(Icons.close, size: 14, color: Colors.grey)),
    ]),
  );

  Widget _buildImportCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.importFromExcel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
      const SizedBox(height: 8),
      Text(AppLocalizations.of(context)!.uploadExcelHint, style: TextStyle(fontSize: 13, color: AppColors.darkColor.withValues(alpha: 0.6))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isImporting ? null : _importFromExcel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isImporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.upload_file),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(_isImporting ? 'Importing...' : 'Upload Excel', style: const TextStyle(fontWeight: FontWeight.bold))),
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
      ]),
      if (_importMessage != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          Icon(_importErrors.isEmpty ? Icons.check_circle : Icons.warning_amber, color: _importErrors.isEmpty ? AppColors.successColor : AppColors.warningColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_importMessage!, style: TextStyle(fontSize: 13, color: AppColors.darkColor, fontWeight: FontWeight.w600))),
        ]),
      ],
      if (_importErrors.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.errorColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _importErrors.take(5).map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: TextStyle(fontSize: 12, color: AppColors.errorColor)))).toList(),
          ),
        ),
        if (_importErrors.length > 5) Text('...and ${_importErrors.length - 5} more errors', style: TextStyle(fontSize: 12, color: AppColors.errorColor)),
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
        Expanded(child: Text('Students to Delete (${_codesList.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
          ),
          child: const Text('Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
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
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)))),
            const SizedBox(width: 12),
            Expanded(child: Text(_codesList[i], style: TextStyle(color: AppColors.darkColor, fontWeight: FontWeight.w500))),
            GestureDetector(
              onTap: () => setState(() => _codesList.removeAt(i)),
              child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
          ]),
        ),
      ),
    ]),
  );
}
