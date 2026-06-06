import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/api_service.dart';
import '../../Auth/colors.dart';

/// صفحة عرض الطلاب المسجلين في الكورس
/// GET /Course/get-enrolled-students/{courseId}?search=
/// مع Debounce 300ms على حقل البحث
class EnrolledStudentsPage extends StatefulWidget {
  final String courseId;
  const EnrolledStudentsPage({super.key, required this.courseId});

  @override
  State<EnrolledStudentsPage> createState() => _EnrolledStudentsPageState();
}

class _EnrolledStudentsPageState extends State<EnrolledStudentsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _students = [];
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchCtrl.text != _lastSearch) {
        _lastSearch = _searchCtrl.text;
        _fetch(search: _lastSearch);
      }
    });
  }

  Future<void> _fetch({String? search}) async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      // URL الصحيح: GET /Course/get-enrolled-students/{courseId}?search=
      final res = await ApiService.getEnrolledStudents(
        courseId: widget.courseId,
        token: token,
        search: search?.isNotEmpty == true ? search : null,
      );

      if (res['statusCode'] == 200) {
        final data = jsonDecode(res['body']);
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey(r'$values')) list = data[r'$values'] ?? [];

        if (mounted) setState(() => _students = list);
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
    const Color accent = Color(0xFF0277BD);

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: const Text('Enrolled Students'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetch(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null),
          ),
        ],
        bottom: PreferredSize(
          // Desktop Layout: 60px height / Mobile Layout: 52px height
          preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.width < 600 ? 52 : 60, // Mobile: 52 / Desktop: 60
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or university code...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () => _searchCtrl.clear(),
                  ),
              ]),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
        children: [
          if (!_isLoading && _errorMessage.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.group, size: 18, color: accent),
                const SizedBox(width: 8),
                Text('${_students.length} student(s) enrolled',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: accent)),
              ]),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : _errorMessage.isNotEmpty
                    ? _buildError()
                    : _students.isEmpty
                        ? _buildEmpty()
                        : LayoutBuilder(builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            // Desktop Layout: 3 cols ≥900 / Tablet: 2 cols ≥600 / Mobile Layout: 1 col <600
                            final cols = w >= 1100 ? 4 : w >= 850 ? 3 : w >= 600 ? 2 : 1;
                            final isMobile = w < 600; // Mobile Layout breakpoint
                            if (cols > 1) {
                              return GridView.builder(
                                // Desktop Layout: generous padding / Mobile Layout: compact padding
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: isMobile ? 8 : 10,  // Mobile: 8 / Desktop: 10
                                  crossAxisSpacing: isMobile ? 8 : 10, // Mobile: 8 / Desktop: 10
                                  mainAxisExtent: 90,
                                ),
                                itemCount: _students.length,
                                itemBuilder: (_, i) => _studentCard(_students[i], i + 1, isMobile: isMobile),
                              );
                            }
                            // Mobile Layout: single-column list
                            return ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 12 : 16), // Mobile: 12 / Desktop: 16
                              itemCount: _students.length,
                              itemBuilder: (_, i) => _studentCard(_students[i], i + 1, isMobile: isMobile),
                            );
                          }),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student, int rank, {bool isMobile = false}) {
    final String name = student['studentName'] ?? student['name'] ?? 'Unknown';
    final String code = student['universityCode'] ?? student['code'] ?? '—';
    final String email = student['email'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 10), // Mobile: 8 / Desktop: 10
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        // Mobile Layout: compact padding / Desktop Layout: standard padding
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16, // Mobile: 12 / Desktop: 16
          vertical: isMobile ? 6 : 8,    // Mobile: 6 / Desktop: 8
        ),
        leading: CircleAvatar(
          // Mobile Layout: smaller avatar / Desktop Layout: standard avatar
          radius: isMobile ? 18 : 20, // Mobile: 18 / Desktop: 20
          backgroundColor: const Color(0xFF0277BD).withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: const Color(0xFF0277BD),
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 14, // Mobile: 13 / Desktop: 14
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Mobile Layout: smaller name / Desktop Layout: standard name
            fontSize: isMobile ? 13 : 14, // Mobile: 13 / Desktop: 14
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Code: $code',
            style: TextStyle(
              color: AppColors.darkColor.withValues(alpha: 0.5),
              fontSize: isMobile ? 11 : 12, // Mobile: 11 / Desktop: 12
            ),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                color: AppColors.darkColor.withValues(alpha: 0.4),
                fontSize: isMobile ? 10 : 11, // Mobile: 10 / Desktop: 11
              ),
            ),
        ]),
        trailing: Text(
          '#$rank',
          style: TextStyle(
            color: AppColors.darkColor.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 13, // Mobile: 12 / Desktop: 13
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
    const SizedBox(height: 16),
    Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.errorColor)),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _fetch, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0277BD)), child: const Text('Retry')),
  ])));

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.people_outline, size: 72, color: AppColors.darkColor.withValues(alpha: 0.2)),
    const SizedBox(height: 16),
    Text(
      _searchCtrl.text.isEmpty ? 'No students enrolled yet' : 'No students match your search',
      style: TextStyle(fontSize: 16, color: AppColors.darkColor.withValues(alpha: 0.5)),
      textAlign: TextAlign.center,
    ),
  ]));
}
