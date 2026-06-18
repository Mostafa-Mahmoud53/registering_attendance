import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/network/api_service.dart';
import '../../../core/constants/app_colors.dart';

class SectionReportPage extends StatefulWidget {
  final String courseId;
  const SectionReportPage({super.key, required this.courseId});

  @override
  State<SectionReportPage> createState() => _SectionReportPageState();
}

class _SectionReportPageState extends State<SectionReportPage> {
  final TextEditingController _marksCtrl = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  int _totalSections = 0;
  double? _marksAssigned;
  List<dynamic> _students = [];
  bool _isExporting = false;

  static const Color _accent = Color(0xFF2E7D32); // Green

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _marksCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({String? totalMarks}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      // URL الصحيح: GET /Attendance/section-report/{courseId}?totalMarks=X
      final res = await ApiService.getSectionReport(
        courseId: widget.courseId,
        token: token,
        totalMarks: totalMarks,
      );

      if (res['statusCode'] == 200) {
        final data = jsonDecode(res['body']);
        List<dynamic> students = [];
        if (data['students'] is List) {
          students = data['students'];
        } else if (data['students'] is Map &&
            data['students'].containsKey(r'$values')) {
          students = data['students'][r'$values'] ?? [];
        }
        setState(() {
          _totalSections =
              data['courseTotalLectures'] ?? data['courseTotalSections'] ?? 0;
          _marksAssigned = data['totalMarksAssigned'] != null
              ? (data['totalMarksAssigned'] as num).toDouble()
              : null;
          _students = students;
        });
      } else if (res['statusCode'] == 403) {
        setState(
          () =>
              _errorMessage = 'Forbidden: You are not assigned to this course.',
        );
      } else {
        setState(
          () => _errorMessage = 'Error ${res['statusCode']}: ${res['body']}',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    if (_students.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      final workbook = excel.Excel.createExcel();
      final sheetName = 'Section Report';
      final sheet = workbook[sheetName];

      // Remove the default "Sheet1" so the file opens on the report sheet
      if (workbook.sheets.containsKey('Sheet1')) {
        workbook.delete('Sheet1');
      }

      // ── Define styles ──────────────────────────────────────────────
      final headerStyle = excel.CellStyle(
        bold: true,
        fontSize: 13,
        fontFamily: 'Calibri',
        fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: excel.ExcelColor.fromHexString('#2E7D32'),
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        textWrapping: excel.TextWrapping.WrapText,
        topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin, borderColorHex: excel.ExcelColor.fromHexString('#1B5E20')),
        bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin, borderColorHex: excel.ExcelColor.fromHexString('#1B5E20')),
        leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin, borderColorHex: excel.ExcelColor.fromHexString('#1B5E20')),
        rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin, borderColorHex: excel.ExcelColor.fromHexString('#1B5E20')),
      );

      final dataBorder = excel.Border(borderStyle: excel.BorderStyle.Thin, borderColorHex: excel.ExcelColor.fromHexString('#D0D0D0'));

      final dataStyleEven = excel.CellStyle(
        fontSize: 11,
        fontFamily: 'Calibri',
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        backgroundColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        topBorder: dataBorder,
        bottomBorder: dataBorder,
        leftBorder: dataBorder,
        rightBorder: dataBorder,
      );

      final dataStyleOdd = excel.CellStyle(
        fontSize: 11,
        fontFamily: 'Calibri',
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
        backgroundColorHex: excel.ExcelColor.fromHexString('#F1F8E9'),
        topBorder: dataBorder,
        bottomBorder: dataBorder,
        leftBorder: dataBorder,
        rightBorder: dataBorder,
      );

      final nameStyleEven = excel.CellStyle(
        fontSize: 11,
        fontFamily: 'Calibri',
        horizontalAlign: excel.HorizontalAlign.Left,
        verticalAlign: excel.VerticalAlign.Center,
        backgroundColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        topBorder: dataBorder,
        bottomBorder: dataBorder,
        leftBorder: dataBorder,
        rightBorder: dataBorder,
      );

      final nameStyleOdd = excel.CellStyle(
        fontSize: 11,
        fontFamily: 'Calibri',
        horizontalAlign: excel.HorizontalAlign.Left,
        verticalAlign: excel.VerticalAlign.Center,
        backgroundColorHex: excel.ExcelColor.fromHexString('#F1F8E9'),
        topBorder: dataBorder,
        bottomBorder: dataBorder,
        leftBorder: dataBorder,
        rightBorder: dataBorder,
      );

      // ── Set column widths ──────────────────────────────────────────
      sheet.setColumnWidth(0, 8);   // #
      sheet.setColumnWidth(1, 35);  // Student Name
      sheet.setColumnWidth(2, 18);  // University Code
      sheet.setColumnWidth(3, 16);  // Sections Attended
      sheet.setColumnWidth(4, 16);  // Absences
      final bool hasMarks = _marksAssigned != null;
      if (hasMarks) {
        sheet.setColumnWidth(5, 16); // Earned Marks
      }

      // ── Header row ─────────────────────────────────────────────────
      final headers = [
        excel.TextCellValue('#'),
        excel.TextCellValue('Student Name'),
        excel.TextCellValue('University Code'),
        excel.TextCellValue('Sections Attended'),
        excel.TextCellValue('Absences'),
        if (hasMarks) excel.TextCellValue('Earned Marks'),
      ];
      sheet.appendRow(headers);

      // Apply header style
      for (int c = 0; c < headers.length; c++) {
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = headerStyle;
      }

      // ── Data rows ──────────────────────────────────────────────────
      for (int i = 0; i < _students.length; i++) {
        final student = _students[i];
        final name = student['studentName']?.toString() ?? 'Unknown';
        final code = student['universityCode']?.toString() ?? '—';
        final attended = student['lectureAttended'] ?? student['sectionAttended'] ?? 0;
        final backendAbsent = student['absenceInLectures'] ?? student['absenceInSections'] ?? 0;
        final absent = _totalSections > 0 ? (_totalSections - (attended as int)) : backendAbsent;
        final double? marks = student['earnedMarks'] != null
            ? (student['earnedMarks'] as num).toDouble()
            : null;

        final row = <excel.CellValue>[
          excel.IntCellValue(i + 1),
          excel.TextCellValue(name),
          excel.TextCellValue(code),
          excel.IntCellValue(attended is int ? attended : int.tryParse(attended.toString()) ?? 0),
          excel.IntCellValue(absent is int ? absent : int.tryParse(absent.toString()) ?? 0),
          if (hasMarks)
            marks != null
                ? excel.DoubleCellValue(marks)
                : excel.TextCellValue('—'),
        ];
        sheet.appendRow(row);

        // Apply alternating row styles
        final isOdd = i % 2 == 1;
        final rowIndex = i + 1; // +1 because row 0 is header
        for (int c = 0; c < row.length; c++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
          if (c == 1) {
            // Name column: left-aligned
            cell.cellStyle = isOdd ? nameStyleOdd : nameStyleEven;
          } else {
            cell.cellStyle = isOdd ? dataStyleOdd : dataStyleEven;
          }
        }
      }

      // ── Save and share ─────────────────────────────────────────────
      final directory = await getTemporaryDirectory();
      final fileName = 'section_report_${widget.courseId}.xlsx';
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Failed to generate Excel file.');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(filePath)], text: 'Section report export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sectionReport),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetch(
              totalMarks: _marksCtrl.text.isNotEmpty ? _marksCtrl.text : null,
            ),
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.file_download),
            onPressed: _isExporting || _students.isEmpty
                ? null
                : _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _marksCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Total Marks (optional)',
                          hintText: 'e.g. 10',
                          prefixIcon: const Icon(Icons.grade, color: _accent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _fetch(
                              totalMarks: _marksCtrl.text.isNotEmpty
                                  ? _marksCtrl.text
                                  : null,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        foregroundColor: AppColors.darkColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.apply),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _errorMessage.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _pill(
                        Icons.science,
                        'Total Sections: $_totalSections',
                        _accent,
                      ),
                      if (_marksAssigned != null) ...[
                        const SizedBox(width: 10),
                        _pill(
                          Icons.star,
                          'Marks: ${_marksAssigned!.toStringAsFixed(1)}',
                          AppColors.warningColor,
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_errorMessage.isNotEmpty) return _errorState();
    if (_students.isEmpty) return _emptyState();

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= 1100 ? 4 : w >= 850 ? 3 : w >= 600 ? 2 : 1;
      final isMobile = w < 600; // Mobile Layout breakpoint
      if (cols > 1) {
        return GridView.builder(
          // Desktop Layout: generous padding / Mobile Layout: compact padding
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: isMobile ? 8 : 12,  // Mobile: 8 / Desktop: 12
            crossAxisSpacing: isMobile ? 8 : 12, // Mobile: 8 / Desktop: 12
            mainAxisExtent: 155,
          ),
          itemCount: _students.length,
          itemBuilder: (_, i) => _studentCard(_students[i], isMobile: isMobile),
        );
      }
      // Mobile Layout: single-column list with compact padding
      return ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 16), // Mobile: 12 / Desktop: 16
        itemCount: _students.length,
        itemBuilder: (_, i) => _studentCard(_students[i], isMobile: isMobile),
      );
    });
  }

  Widget _studentCard(Map<String, dynamic> s, {bool isMobile = false}) {
    final String name = s['studentName'] ?? 'Unknown';
    final String code = s['universityCode'] ?? '—';
    final int attended = s['lectureAttended'] ?? s['sectionAttended'] ?? 0;
    final int backendAbsent = s['absenceInLectures'] ?? s['absenceInSections'] ?? 0;
    final int absent = _totalSections > 0 ? (_totalSections - attended) : backendAbsent;
    final double? marks = s['earnedMarks'] != null
        ? (s['earnedMarks'] as num).toDouble()
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12), // Mobile: 8 / Desktop: 12
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        // Mobile Layout: compact padding / Desktop Layout: standard padding
        padding: EdgeInsets.all(isMobile ? 12 : 16), // Mobile: 12 / Desktop: 16
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  // Mobile Layout: smaller avatar / Desktop Layout: standard avatar
                  radius: isMobile ? 18 : 20, // Mobile: 18 / Desktop: 20
                  backgroundColor: _accent.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14, // Mobile: 13 / Desktop: 14
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12), // Mobile: 8 / Desktop: 12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          // Mobile Layout: smaller name / Desktop Layout: standard name
                          fontSize: isMobile ? 13 : 15, // Mobile: 13 / Desktop: 15
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Code: $code',
                        style: TextStyle(
                          color: AppColors.darkColor.withValues(alpha: 0.5),
                          fontSize: isMobile ? 11 : 12, // Mobile: 11 / Desktop: 12
                        ),
                      ),
                    ],
                  ),
                ),
                if (marks != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10, // Mobile: 8 / Desktop: 10
                      vertical: isMobile ? 4 : 5,    // Mobile: 4 / Desktop: 5
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${marks.toStringAsFixed(1)} pts',
                      style: TextStyle(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13, // Mobile: 11 / Desktop: 13
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Attended', attended.toString(), Colors.green, isMobile: isMobile),
                _miniStat('Absent', absent.toString(), AppColors.errorColor, isMobile: isMobile),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.errorColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetch,
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.speaker_notes_off,
          size: 72,
          color: AppColors.darkColor.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 16),
        Text(
          'No attendance records',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );

  Widget _pill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _miniStat(String label, String val, Color color, {bool isMobile = false}) => Column(
    children: [
      Text(
        val,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          // Mobile Layout: smaller value / Desktop Layout: standard value
          fontSize: isMobile ? 16 : 20, // Mobile: 16 / Desktop: 20
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 11 : 12, // Mobile: 11 / Desktop: 12
          color: AppColors.darkColor.withValues(alpha: 0.5),
        ),
      ),
    ],
  );
}
