import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../Auth/api_service.dart';
import '../../Auth/colors.dart';

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
      final sheet = workbook['Section Report'];

      sheet.appendRow([
        excel.TextCellValue('Student Name'),
        excel.TextCellValue('Grade'),
      ]);

      for (final student in _students) {
        final name = student['studentName']?.toString() ?? 'Unknown';
        sheet.appendRow([excel.TextCellValue(name), excel.TextCellValue('')]);
      }

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
