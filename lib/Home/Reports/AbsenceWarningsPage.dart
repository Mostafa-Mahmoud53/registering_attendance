import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/api_service.dart';
import '../../Auth/colors.dart';
import '../../l10n/app_localizations.dart';

class AbsenceWarningsPage extends StatefulWidget {
  final String courseId;
  const AbsenceWarningsPage({Key? key, required this.courseId}) : super(key: key);

  @override
  State<AbsenceWarningsPage> createState() => _AbsenceWarningsPageState();
}

class _AbsenceWarningsPageState extends State<AbsenceWarningsPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _warnings = [];
  int _totalLectures = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      // URL الصحيح: GET /Attendance/absence-warnings/{courseId}
      final res = await ApiService.getAbsenceWarnings(courseId: widget.courseId, token: token);

      if (res['statusCode'] == 200) {
        final data = jsonDecode(res['body']);
        List<dynamic> list = [];
        int total = 0;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          total = data['courseTotalLectures'] ?? data['totalLectures'] ?? 0;
          final raw = data['students'] ?? data[r'$values'] ?? data;
          if (raw is List) list = raw;
          else if (raw is Map && raw.containsKey(r'$values')) list = raw[r'$values'] ?? [];
        }
        setState(() { _warnings = list; _totalLectures = total; });
      } else if (res['statusCode'] == 403) {
        setState(() => _errorMessage = 'Forbidden: You are not assigned to this course.');
      } else {
        setState(() => _errorMessage = 'Error ${res['statusCode']}: ${res['body']}');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(loc.absenceWarningsPageTitle),
        backgroundColor: AppColors.errorColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.errorColor))
              : _errorMessage.isNotEmpty
                  ? _buildError(loc)
                  : _warnings.isEmpty
                      ? _buildEmpty(loc)
                      : _buildList(),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations loc) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
    const SizedBox(height: 16),
    Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.errorColor)),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _fetch, style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor), child: Text(loc.retry)),
  ])));

  Widget _buildEmpty(AppLocalizations loc) {
    final bool notEnough = _totalLectures <= 3;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(notEnough ? Icons.schedule : Icons.check_circle_outline,
          size: 80, color: notEnough ? Colors.orange : Colors.green),
      const SizedBox(height: 20),
      Text(
        notEnough
            ? loc.noDataAvailable
            : loc.noStudentsFound,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    ])));
  }

  Widget _buildList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.errorColor.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('${_warnings.length} ${AppLocalizations.of(context)!.students}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorColor)),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            // Desktop Layout: 3 cols ≥900 / Tablet Layout: 2 cols ≥600 / Mobile Layout: 1 col <600
            final cols = w >= 900 ? 3 : w >= 600 ? 2 : 1;
            final isMobile = w < 600; // Mobile Layout breakpoint
            if (cols > 1) {
              return GridView.builder(
                // Desktop Layout: generous padding / Mobile Layout: compact padding
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: isMobile ? 8 : 12,  // Mobile: 8 / Desktop: 12
                  crossAxisSpacing: isMobile ? 8 : 12, // Mobile: 8 / Desktop: 12
                  childAspectRatio: cols == 3 ? 1.2 : 1.4, // Desktop Layout
                ),
                itemCount: _warnings.length,
                itemBuilder: (_, i) => _buildWarningCard(_warnings[i], isMobile: isMobile),
              );
            }
            // Mobile Layout: single-column list
            return ListView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 16), // Mobile: 12 / Desktop: 16
              itemCount: _warnings.length,
              itemBuilder: (_, i) => _buildWarningCard(_warnings[i], isMobile: isMobile),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWarningCard(dynamic w, {bool isMobile = false}) {
    final String name = w['studentName'] ?? 'Unknown';
    final String code = w['universityCode'] ?? '—';
    final int attended = w['lectureAttended'] ?? w['attended'] ?? 0;
    final int absent = w['absenceInLectures'] ?? w['absent'] ?? 0;
    final int total = (attended + absent);
    final double pct = total > 0 ? (attended / total) * 100 : 0;

    return Card(
      // Mobile Layout: compact margin / Desktop Layout: standard margin
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12), // Mobile: 8 / Desktop: 12
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        // Mobile Layout: compact padding / Desktop Layout: standard padding
        padding: EdgeInsets.all(isMobile ? 12 : 16), // Mobile: 12 / Desktop: 16
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              // Mobile Layout: smaller avatar / Desktop Layout: standard avatar
              radius: isMobile ? 18 : 20, // Mobile: 18 / Desktop: 20
              backgroundColor: AppColors.errorColor.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 13 : 14, // Mobile: 13 / Desktop: 14
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12), // Mobile: 8 / Desktop: 12
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // Mobile Layout: smaller name / Desktop Layout: standard name
                  fontSize: isMobile ? 13 : 14, // Mobile: 13 / Desktop: 14
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${AppLocalizations.of(context)!.code}: $code',
                style: TextStyle(
                  color: AppColors.darkColor.withOpacity(0.5),
                  fontSize: isMobile ? 11 : 12, // Mobile: 11 / Desktop: 12
                ),
              ),
            ])),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10, // Mobile: 8 / Desktop: 10
                vertical: isMobile ? 4 : 5,    // Mobile: 4 / Desktop: 5
              ),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 13, // Mobile: 12 / Desktop: 13
                ),
              ),
            ),
          ]),
          SizedBox(height: isMobile ? 8 : 12), // Mobile: 8 / Desktop: 12
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? attended / total : 0,
              backgroundColor: AppColors.errorColor.withOpacity(0.15),
              color: pct >= 75 ? Colors.green : (pct >= 50 ? Colors.orange : AppColors.errorColor),
              // Mobile Layout: slimmer bar / Desktop Layout: standard bar
              minHeight: isMobile ? 6 : 8, // Mobile: 6 / Desktop: 8
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8), // Mobile: 6 / Desktop: 8
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              '${AppLocalizations.of(context)!.attended}: $attended',
              style: TextStyle(
                color: Colors.green,
                // Mobile Layout: smaller stat text / Desktop Layout: standard stat text
                fontSize: isMobile ? 12 : 13, // Mobile: 12 / Desktop: 13
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${AppLocalizations.of(context)!.absent}: $absent',
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: isMobile ? 12 : 13, // Mobile: 12 / Desktop: 13
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
