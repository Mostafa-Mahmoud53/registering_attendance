import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle_button.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../core/responsive.dart';
import '../Auth/auth_storage.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';
import 'Reports/CourseDashboardPage.dart';
// import 'creatCourse.dart'; // Removed as unused

/// الشاشة الرئيسية للدكتور / TA بعد تسجيل الدخول
class DoctorDashboardPage extends StatefulWidget {
  final String userName;
  final String email;
  final String role;
  final String token;

  const DoctorDashboardPage({
    super.key,
    required this.userName,
    required this.email,
    required this.role,
    required this.token,
  });

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  int _totalStudents = 0;

  static const String _myCoursesUrl = '${ApiService.baseUrl}/Course/my-courses';

  final List<Color> _colors = [
    const Color(0xFF1A9E8F),
    const Color(0xFF2E7D32),
    const Color(0xFF1565C0),
    const Color(0xFF6A1B9A),
    const Color(0xFFE65100),
    const Color(0xFF880E4F),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadAndFetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  Future<void> _loadAndFetch() async {
    await _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(
        Uri.parse(_myCoursesUrl),
        headers: {'accept': '*/*', 'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        List<dynamic> raw = decoded is List
            ? decoded
            : (decoded is Map && decoded.containsKey(r'$values'))
            ? decoded[r'$values'] ?? []
            : [];

        List<Map<String, dynamic>> courses = [];
        for (int i = 0; i < raw.length; i++) {
          var c = raw[i];
          courses.add({
            'id': c['id']?.toString() ?? '',
            'name': c['name'] ?? 'Unknown',
            'doctorName': c['doctorName'] ?? '',
            'studentCount': null,
            'role': c['role'],
            'staff': c['staff'],
            'code': c['code'] ?? '',
            'color': _colors[i % _colors.length],
          });
        }

        // جلب عدد الطلاب لكل كورس
        await _fetchEnrolledCounts(courses);

        int total = 0;
        for (var c in courses) {
          total += (c['studentCount'] as int? ?? 0);
        }

        if (mounted) {
          setState(() {
            _allCourses = courses;
            _totalStudents = total;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // انتهت الجلسة - تسجيل خروج تلقائي
        _handleAutoLogout();
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error ${response.statusCode}';
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
    }
  }

  Future<void> _fetchEnrolledCounts(List<Map<String, dynamic>> courses) async {
    await Future.wait(
      courses.map((c) async {
        try {
          final res = await ApiService.getEnrolledCount(
            courseId: c['id'],
            token: widget.token,
          );
          if (res['statusCode'] == 200) {
            final data = jsonDecode(res['body']);
            c['studentCount'] = data is int
                ? data
                : (int.tryParse(data['count']?.toString() ?? '') ?? 0);
          }
        } catch (_) {}
      }),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _allCourses;
    return _allCourses
        .where(
          (c) =>
              c['name'].toString().toLowerCase().contains(_searchQuery) ||
              c['id'].toString().contains(_searchQuery),
        )
        .toList();
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.logout,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.areYouSureLogout,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.darkColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.logout,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm == true && mounted) {
      await _handleAutoLogout();
    }
  }

  Future<void> _handleAutoLogout() async {
    if (!mounted) return;
    await AuthStorage.clearUserData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: CustomScrollView(
            slivers: [
              // ── 1. Header (نفس شكل AdminDashboard) ────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                collapsedHeight: 80,
                pinned: true,
                floating: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primaryColor,
                elevation: 8,
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: Responsive.isDesktop(context)
                      ? const EdgeInsetsDirectional.only(start: 40, bottom: 20)
                      : const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        radius: Responsive.isDesktop(context) ? 20 : 16,
                        child: Icon(
                          Icons.school,
                          color: Colors.white,
                          size: Responsive.isDesktop(context) ? 24 : 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.role == 'Admin'
                                  ? AppLocalizations.of(context)!.adminDashboard
                                  : (widget.role == 'Doctor'
                                        ? AppLocalizations.of(
                                            context,
                                          )!.doctorDashboard
                                        : '${widget.role} Dashboard'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.isDesktop(context)
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.userName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: Responsive.isDesktop(context)
                                    ? 14
                                    : 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryColor, AppColors.darkColor],
                      ),
                    ),
                  ),
                ),
                actions: [
                  LanguageToggleButton(),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _logout,
                  ),
                  const SizedBox(width: 10),
                ],
              ),

              // ── 2. Welcome Card (نفس شكل AdminDashboard) ──────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        Responsive.isDesktop(context) ? 12 : 24,
                        20,
                        0,
                      ),
                      child: Container(
                        padding: Responsive.isDesktop(context)
                            ? const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              )
                            : const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.lightColor, Colors.white],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: Responsive.isDesktop(context) ? 60 : 60,
                              height: Responsive.isDesktop(context) ? 60 : 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.secondaryColor,
                                    AppColors.accentColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: Responsive.isDesktop(context) ? 30 : 30,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.welcome} ${widget.role},',
                                  style: TextStyle(
                                    fontSize: Responsive.isDesktop(context)
                                        ? 15
                                        : 16,
                                    color: AppColors.darkColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: Responsive.isDesktop(context)
                                        ? 22
                                        : 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkColor,
                                  ),
                                ),
                                Text(
                                  widget.email,
                                  style: TextStyle(
                                    fontSize: Responsive.isDesktop(context)
                                        ? 14
                                        : 13,
                                    color: AppColors.darkColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.isDesktop(context) ? 40 : 20,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatCard(
                          icon: Icons.book,
                          title: AppLocalizations.of(context)!.totalCourses,
                          count: _isLoading
                              ? '...'
                              : _allCourses.length.toString(),
                          color: AppColors.primaryColor,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCompactStatCard(
                          icon: Icons.people,
                          title: AppLocalizations.of(context)!.totalStudents,
                          count: _isLoading ? '...' : _totalStudents.toString(),
                          color: AppColors.successColor,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 5. Courses Label ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.isDesktop(context) ? 20 : 20,
                    24,
                    20,
                    12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      AppLocalizations.of(context)!.myCourses,
                      textAlign: Responsive.isDesktop(context)
                          ? TextAlign.center
                          : TextAlign.start,
                      style: TextStyle(
                        fontSize: Responsive.isDesktop(context) ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                  ),
                ),
              ),

              // ── 6. Course List ─────────────────────────────────────────────────
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                SliverFillRemaining(child: _buildError())
              else if (_filtered.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                Builder(
                  builder: (context) {
                    final w = MediaQuery.of(context).size.width;
                    // Desktop Layout: 1 col (full width) / Tablet Layout: 2 cols ≥ 850 / Mobile Layout: 1 col < 850
                    final cols = w >= 1100
                        ? 1
                        : w >= 850
                        ? 2
                        : 1;
                    if (cols > 1) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: Responsive.isDesktop(context)
                                ? 170
                                : null,
                            childAspectRatio: Responsive.isDesktop(context)
                                ? 1.0
                                : 1.9, // Overridden by mainAxisExtent on desktop
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _courseCard(_filtered[i]),
                            childCount: _filtered.length,
                          ),
                        ),
                      );
                    }
                    // Mobile Layout: single-column list
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _courseCard(_filtered[i]),
                        ),
                        childCount: _filtered.length,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkColor,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(Map<String, dynamic> course) {
    final Color color = course['color'] as Color;
    final String? role = course['role']?.toString();
    final dynamic count = course['studentCount'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDashboardPage(course: course),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: Responsive.isDesktop(context) ? 6 : 4,
                height: Responsive.isDesktop(context) ? 70 : 70,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.isDesktop(context) ? 10 : 8,
                            vertical: Responsive.isDesktop(context) ? 4 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: ${course['id']}',
                            style: TextStyle(
                              color: color,
                              fontSize: Responsive.isDesktop(context) ? 12 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            count == null
                                ? '— students'
                                : '$count student${count == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: Responsive.isDesktop(context) ? 13 : 11,
                            ),
                          ),
                          backgroundColor: AppColors.lightColor,
                          visualDensity: VisualDensity.compact,
                          padding: Responsive.isDesktop(context)
                              ? const EdgeInsets.all(4)
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.isDesktop(context) ? 8 : 8),
                    Text(
                      course['name'],
                      style: TextStyle(
                        fontSize: Responsive.isDesktop(context) ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    if (role != null) ...[
                      SizedBox(height: Responsive.isDesktop(context) ? 8 : 8),
                      Chip(
                        label: Text(
                          role,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.isDesktop(context) ? 12 : 12,
                          ),
                        ),
                        backgroundColor: role.toLowerCase().contains('main')
                            ? Colors.blue
                            : Colors.grey,
                        visualDensity: VisualDensity.compact,
                        padding: Responsive.isDesktop(context)
                            ? const EdgeInsets.all(4)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: Responsive.isDesktop(context) ? 16 : 8),
              Icon(
                Icons.arrow_forward_ios,
                size: Responsive.isDesktop(context) ? 24 : 16,
                color: AppColors.darkColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
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
          ElevatedButton.icon(
            onPressed: _fetchCourses,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.book_outlined,
          size: 80,
          color: AppColors.darkColor.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isEmpty
              ? AppLocalizations.of(context)!.noCoursesAssigned
              : AppLocalizations.of(context)!.noCoursesMatch,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );
}
