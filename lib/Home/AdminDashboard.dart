// ignore_for_file: avoid_print
// admin_dashboard.dart مع إصلاح خطأ نوع البيانات وتحسين الأداء
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/responsive.dart';
import 'package:registering_attendance/Home/CoursesListPage.dart';
import 'package:registering_attendance/Home/CreateStudentsTabsPage.dart';
import 'package:registering_attendance/Home/DeleteStudentsTabsPage.dart';
import 'package:registering_attendance/Home/DoctorsListPage.dart';
import 'package:registering_attendance/Home/ResetStudentsAccountsPage.dart';
import 'package:registering_attendance/Home/TAsListPage.dart';
import 'package:registering_attendance/Home/creatCourse.dart';
import 'package:registering_attendance/Home/creatDoctorOrTA.dart';
import 'package:registering_attendance/Home/AssignStaffPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/auth_storage.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';
import '../widgets/language_toggle_button.dart';

class AdminDashboard extends StatefulWidget {
  final String userName;
  final String email;
  final String role;
  final String token;

  const AdminDashboard({
    super.key,
    required this.userName,
    required this.email,
    required this.role,
    required this.token,
  });

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final StreamController<Map<String, dynamic>> _statsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  late Timer _refreshTimer;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();

    // تحديث الإحصائيات كل 30 ثانية تلقائياً
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty && _userRole == 'Admin') {
        _fetchStatistics();
      }
    });
  }

  @override
  void dispose() {
    _statsStreamController.close();
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadAuthTokenAndStartStream();
  }

  Future<void> _loadAuthTokenAndStartStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('user_role');
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        // بيانات أولية أثناء التحميل
        _statsStreamController.add({
          'doctors': 0,
          'tas': 0,
          'students': 0,
          'courses': 0,
          'loading': true,
        });

        // جلب البيانات فقط للـ Admin
        if (_userRole == 'Admin') {
          await _fetchStatistics();
        } else {
          // للدكتور والـ TA - لا توجد إحصائيات Admin
          _statsStreamController.add({
            'doctors': 0,
            'tas': 0,
            'students': 0,
            'courses': 0,
            'error': 'non_admin',
          });
        }
      } else {
        print('⚠️ No token found in SharedPreferences');
        _statsStreamController.add({
          'doctors': 0,
          'tas': 0,
          'students': 0,
          'courses': 0,
          'error': 'no_token',
        });
      }
    } catch (e) {
      print('❌ Error loading token: $e');
      _statsStreamController.add({
        'doctors': 0,
        'tas': 0,
        'students': 0,
        'courses': 0,
        'error': 'load_error',
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _fetchStatistics() async {
    print('\n📊 Fetching Statistics...');

    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      print('❌ Auth token is null or empty!');
      _statsStreamController.add({
        'doctors': 0,
        'tas': 0,
        'students': 0,
        'courses': 0,
        'error': 'no_token',
      });
      return;
    }

    try {
      // قائمة endpoints - تأكد من مطابقتها تماماً مع الـ API
      final endpoints = [
        {'key': 'doctors', 'endpoint': 'number-of-doctors'},
        {'key': 'tas', 'endpoint': 'number-of-TAs'},
        {'key': 'students', 'endpoint': 'number-of-students'},
        {'key': 'courses', 'endpoint': 'number-of-courses'},
      ];

      // معالجة النتائج بشكل متسلسل وإرسالها أولاً بأول لتحديث واجهة المستخدم
      final Map<String, dynamic> stats = {
        'doctors': -2,
        'tas': -2,
        'students': -2,
        'courses': -2,
      };
      bool hasError = false;
      final List<String> errors = [];

      // إرسال حالة التحميل الأولية
      _statsStreamController.add(Map.from(stats));

      for (final item in endpoints) {
        final key = item['key']!;
        final result = await _fetchApiData(item['endpoint']!);

        if (result.containsKey('error')) {
          hasError = true;
          errors.add(result['error']);
          stats[key] = -1;
          print('⚠️ Error for $key: ${result['error']}');
        } else if (result.containsKey('count')) {
          final count = result['count'];
          stats[key] = _parseCount(count);
          print('✅ $key: ${stats[key]}');
        } else {
          hasError = true;
          stats[key] = -1;
          print('⚠️ No count for $key');
        }

        // تحديث الواجهة فوراً بعد كل طلب بدلاً من الانتظار
        _statsStreamController.add(Map.from(stats));
      }

      if (hasError) {
        bool hasUnauthorized = errors.any(
          (err) => err == 'unauthorized' || err == 'api_401',
        );
        bool has403 = errors.any((err) => err == 'api_403' || err == 'api_404');

        if (hasUnauthorized) {
          stats['error'] = 'unauthorized';
          // ملاحظة: الـ http_interceptor سيقوم بالتحويل لصفحة تسجيل الدخول تلقائياً
          return;
        } else if (has403) {
          stats['error'] = 'api_403';
        } else {
          stats['error'] = 'partial_error';
        }
      }

      print('📈 Final Stats: $stats');
      _statsStreamController.add(Map.from(stats));
    } catch (e) {
      print('❌ Error in _fetchStatistics: $e');
      _statsStreamController.add({
        'doctors': 0,
        'tas': 0,
        'students': 0,
        'courses': 0,
        'error': 'fetch_error',
      });
    }
  }

  int _parseCount(dynamic count) {
    if (count is int) return count;
    if (count is String) return int.tryParse(count) ?? 0;
    if (count is double) return count.toInt();
    if (count is num) return count.toInt();
    return 0;
  }

  Future<Map<String, dynamic>> _fetchApiData(String endpoint) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      return {'count': 0, 'error': 'no_token'};
    }

    try {
      final response = await ApiService.getAdminStatistic(
        endpoint: endpoint,
        token: token,
      ).timeout(const Duration(seconds: 30));

      final statusCode = response['statusCode'] as int;
      final responseBody = response['body'] as String;

      if (statusCode == 200) {
        try {
          return jsonDecode(responseBody);
        } catch (_) {
          return {'count': 0, 'error': 'parse_error'};
        }
      } else if (statusCode == 401) {
        print('🔒 Unauthorized for $endpoint - Token may be expired');
        return {'count': 0, 'error': 'unauthorized'};
      } else {
        print('⚠️ API Error $statusCode for $endpoint');
        return {'count': 0, 'error': 'api_$statusCode'};
      }
    } on TimeoutException {
      print('⏰ Timeout fetching $endpoint');
      return {'count': 0, 'error': 'timeout'};
    } catch (e) {
      print('❌ Exception fetching $endpoint: $e');
      return {'count': 0, 'error': 'exception'};
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar مع تأثير زجاجي (بدون زر refresh)
              SliverAppBar(
                expandedHeight: 140,
                collapsedHeight: 80,
                pinned: true,
                floating: true,
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
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 16,
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                            Text(
                              widget.userName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                actions: [
                  LanguageToggleButton(),
                  // إزالة زر Refresh وإبقاء زر Logout فقط
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

              // Welcome Card
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        Responsive.isDesktop(context) ? 12 : 24,
                        20,
                        Responsive.isDesktop(context) ? 0 : 24,
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
                          gradient: LinearGradient(
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
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondaryColor,
                                    AppColors.accentColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryColor.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.welcome} ${widget.role},',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.darkColor.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.userName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkColor,
                                    ),
                                  ),
                                  Text(
                                    widget.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.darkColor.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // إضافة مؤشر حالة التحميل
                                  _isLoading
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primaryColor),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.loadingStatistics,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.darkColor
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        )
                                      : StreamBuilder<Map<String, dynamic>>(
                                          stream: _statsStreamController.stream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data!.containsKey(
                                                  'error',
                                                ) &&
                                                snapshot.data!['error'] !=
                                                    null) {
                                              return Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.updatesAutomatically,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.darkColor
                                                      .withValues(alpha: 0.5),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Statistics Cards Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: _statsStreamController.stream,
                    builder: (context, snapshot) {
                      // عرض حالة التحميل
                      if (_isLoading) {
                        return _buildLoadingStatsGrid();
                      }

                      // عرض حالة الخطأ
                      if (snapshot.hasError) {
                        return _buildErrorStatsGrid(
                          message: AppLocalizations.of(
                            context,
                          )!.connectionError,
                          onRetry: _fetchStatistics,
                        );
                      }

                      // عرض حالة لا توجد بيانات
                      if (!snapshot.hasData) {
                        return _buildErrorStatsGrid(
                          message: AppLocalizations.of(
                            context,
                          )!.noDataAvailable,
                          onRetry: _fetchStatistics,
                        );
                      }

                      final stats = snapshot.data!;

                      // التحقق من وجود أخطاء
                      if (stats.containsKey('error') &&
                          stats['error'] != null &&
                          stats['error'] != 'partial_error') {
                        if (stats['error'] == 'api_403' ||
                            widget.role != 'Admin') {
                          return _buildForbiddenStatsGrid(
                            message: AppLocalizations.of(
                              context,
                            )!.noAccessPermission,
                          );
                        }

                        String errorMessage = AppLocalizations.of(
                          context,
                        )!.networkError;
                        if (stats['error'] == 'no_token') {
                          errorMessage = AppLocalizations.of(
                            context,
                          )!.authenticationRequired;
                        } else if (stats['error'] == 'unauthorized') {
                          errorMessage = AppLocalizations.of(
                            context,
                          )!.sessionExpired;
                        }

                        return _buildErrorStatsGrid(
                          message: errorMessage,
                          onRetry: _fetchStatistics,
                        );
                      }

                      // عرض الإحصائيات العادية (أو حالة التحميل -2)
                      final doctors = (stats['doctors'] as int?) ?? -2;
                      final tas = (stats['tas'] as int?) ?? -2;
                      final students = (stats['students'] as int?) ?? -2;
                      final courses = (stats['courses'] as int?) ?? -2;

                      return Column(
                        children: [
                          _buildStatsGrid(
                            doctors: doctors,
                            tas: tas,
                            students: students,
                            courses: courses,
                          ),
                          const SizedBox(height: 8),
                          // رسالة تلقائية للـ auto-refresh
                          Text(
                            AppLocalizations.of(context)!.updatesAutomatically,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.darkColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Main Categories Menu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 20,
                    top: 30,
                    end: 20,
                    bottom: 10,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.dashboardMenu,
                    textAlign: Responsive.isDesktop(context)
                        ? TextAlign.center
                        : TextAlign.start,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkColor,
                    ),
                  ),
                ),
              ),

              // Categories Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: _buildCategoriesGrid(context),
              ),

              // Bottom Space
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  double _statCardWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final available = w > 1400 ? 1400.0 : w;
    if (w >= 1100) {
      return (available - 80) / 4; // Desktop Layout: 4 cards per row
    }
    if (w >= 850) {
      return (available - 60) / 3; // Tablet Layout:  3 cards per row
    }
    if (w >= 600) return (w - 56) / 2 - 6; // Mobile Layout:  2 cards per row
    return (w - 52) / 2; // Mobile Layout (small): 2 compact cards per row
  }

  Widget _buildLoadingStatsGrid() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.hourglass_empty,
                title: AppLocalizations.of(context)!.updatesAutomatically,
                count: '...',
                color: Colors.grey[400]!,
                isLoading: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.loadingStatistics,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStatsGrid({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.error_outline,
                title: 'Error',
                count: '!',
                color: AppColors.errorColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                message,
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForbiddenStatsGrid({required String message}) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.groups,
                title: AppLocalizations.of(context)!.doctors,
                count: '-',
                color: Colors.grey,
              ),
            ),
            SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.school,
                title: AppLocalizations.of(context)!.tas,
                count: '-',
                color: Colors.grey,
              ),
            ),
            SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.people,
                title: AppLocalizations.of(context)!.students,
                count: '-',
                color: Colors.grey,
              ),
            ),
            SizedBox(
              width: _statCardWidth(context),
              child: _buildCompactStatCard(
                icon: Icons.book_online,
                title: AppLocalizations.of(context)!.courses,
                count: '-',
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid({
    required int doctors,
    required int tas,
    required int students,
    required int courses,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: _statCardWidth(context),
          child: _buildCompactStatCard(
            icon: doctors == -1 ? Icons.error_outline : Icons.groups,
            title: AppLocalizations.of(context)!.doctors,
            count: doctors == -1
                ? '!'
                : (doctors == -2 ? '...' : doctors.toString()),
            color: doctors == -1
                ? AppColors.errorColor
                : AppColors.primaryColor,
            isLoading: doctors == -2,
          ),
        ),
        SizedBox(
          width: _statCardWidth(context),
          child: _buildCompactStatCard(
            icon: tas == -1 ? Icons.error_outline : Icons.school,
            title: AppLocalizations.of(context)!.tas,
            count: tas == -1 ? '!' : (tas == -2 ? '...' : tas.toString()),
            color: tas == -1 ? AppColors.errorColor : Colors.blueGrey,
            isLoading: tas == -2,
          ),
        ),
        SizedBox(
          width: _statCardWidth(context),
          child: _buildCompactStatCard(
            icon: students == -1 ? Icons.error_outline : Icons.people,
            title: AppLocalizations.of(context)!.students,
            count: students == -1
                ? '!'
                : (students == -2 ? '...' : students.toString()),
            color: students == -1
                ? AppColors.errorColor
                : AppColors.successColor,
            isLoading: students == -2,
          ),
        ),
        SizedBox(
          width: _statCardWidth(context),
          child: _buildCompactStatCard(
            icon: courses == -1 ? Icons.error_outline : Icons.book_online,
            title: AppLocalizations.of(context)!.courses,
            count: courses == -1
                ? '!'
                : (courses == -2 ? '...' : courses.toString()),
            color: courses == -1 ? AppColors.errorColor : AppColors.accentColor,
            isLoading: courses == -2,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
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
                      fontSize: 12,
                      color: AppColors.darkColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
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

  Widget _buildCategoriesGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final List<Map<String, dynamic>> categories = [];

    if (widget.role == 'Admin') {
      categories.add({
        'title': AppLocalizations.of(context)!.staffManagement,
        'icon': Icons.people_alt,
        'color': Colors.blue,
        'operations': [
          {
            'title': AppLocalizations.of(context)!.createDoctorTA,
            'icon': Icons.person_add,
            'color': AppColors.primaryColor,
            'page': () => CreateAccountPage(),
          },
          {
            'title': AppLocalizations.of(context)!.listDoctors,
            'icon': Icons.list,
            'color': AppColors.primaryColor.withValues(alpha: 0.8),
            'page': () => DoctorsListPage(),
          },
          {
            'title': AppLocalizations.of(context)!.listTAs,
            'icon': Icons.list,
            'color': AppColors.warningColor,
            'page': () => TAsListPage(),
          },
        ],
      });

      categories.add({
        'title': AppLocalizations.of(context)!.studentManagement,
        'icon': Icons.school,
        'color': Colors.orange,
        'operations': [
          {
            'title': AppLocalizations.of(context)!.createStudentsScreen,
            'icon': Icons.person_add,
            'color': AppColors.secondaryColor,
            'page': () => const CreateStudentsTabsPage(),
          },
          {
            'title': AppLocalizations.of(context)!.deleteStudentsScreen,
            'icon': Icons.person_remove,
            'color': AppColors.errorColor,
            'page': () => const DeleteStudentsTabsPage(),
          },
          {
            'title': AppLocalizations.of(context)!.resetAccounts,
            'icon': Icons.manage_accounts,
            'color': AppColors.warningColor,
            'page': () => const ResetStudentsAccountsPage(),
          },
        ],
      });
    }

    categories.add({
      'title': AppLocalizations.of(context)!.courseManagement,
      'icon': Icons.library_books,
      'color': Colors.deepPurple,
      'operations': [
        if (widget.role == 'Admin')
          {
            'title': AppLocalizations.of(context)!.createCourse,
            'icon': Icons.add_circle,
            'color': AppColors.successColor,
            'page': () => CreateCoursePage(),
          },
        {
          'title': AppLocalizations.of(context)!.coursesList,
          'icon': Icons.list_alt,
          'color': AppColors.successColor.withValues(alpha: 0.8),
          'page': () => CoursesListPage(),
        },
        if (widget.role == 'Admin')
          {
            'title': AppLocalizations.of(context)!.assignStaff,
            'icon': Icons.assignment_ind,
            'color': Colors.deepPurple,
            'page': () => const AssignStaffPage(),
          },
      ],
    });

    return SliverToBoxAdapter(
      child: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(categories.length, (index) {
            final cat = categories[index];
            final isMobile = w < 600;
            final available = w > 1400 ? 1400.0 : w;
            final cardW = w >= 1100
                ? (available - 80) / 4
                : w >= 850
                ? (available - 60) / 2
                : isMobile
                ? available - 40
                : (w - 56) / 2 - 6;
            return SizedBox(
              width: cardW,
              child: _buildSimpleOperationCard(
                title: cat['title'] as String,
                icon: cat['icon'] as IconData,
                color: cat['color'] as Color,
                isMobile: isMobile,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubMenuPage(
                        title: cat['title'] as String,
                        operations:
                            cat['operations'] as List<Map<String, dynamic>>,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSimpleOperationCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 16 : 20,
            horizontal: isMobile ? 16 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: isMobile
              ? Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.darkColor.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon'),
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class SubMenuPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> operations;

  const SubMenuPage({super.key, required this.title, required this.operations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        toolbarHeight: Responsive.isDesktop(context) ? 100 : 70,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: Responsive.isDesktop(context) ? 26 : 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: Responsive.isDesktop(context) ? 28 : 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(operations.length, (index) {
                  final op = operations[index];
                  final w = MediaQuery.of(context).size.width;
                  final isMobile = w < 600;
                  final available = w > 1200 ? 1200.0 : w;
                  final cardW = w >= 1100
                      ? (available - 80) / 3
                      : w >= 850
                      ? (available - 60) / 2
                      : isMobile
                      ? available - 40
                      : (w - 56) / 2 - 8;
                  return SizedBox(
                    width: cardW,
                    child: _SubMenuCard(
                      title: op['title']!,
                      icon: op['icon'] as IconData,
                      color: op['color'] as Color,
                      isMobile: isMobile,
                      onTap: () {
                        if (op.containsKey('page') && op['page'] != null) {
                          if (op['page'] is Widget Function()) {
                            final pageBuilder = op['page'] as Widget Function();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => pageBuilder(),
                              ),
                            );
                          } else if (op['page'] is Function) {
                            (op['page'] as Function)();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isMobile;

  const _SubMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 16 : (Responsive.isDesktop(context) ? 24 : 16),
            horizontal: isMobile ? 16 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: isMobile
              ? Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.darkColor.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: Responsive.isDesktop(context) ? 72 : 56,
                      height: Responsive.isDesktop(context) ? 72 : 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: Responsive.isDesktop(context) ? 36 : 32,
                      ),
                    ),
                    SizedBox(height: Responsive.isDesktop(context) ? 16 : 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.isDesktop(context) ? 18 : 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
