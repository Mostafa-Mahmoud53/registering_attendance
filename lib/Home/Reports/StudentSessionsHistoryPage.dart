import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../Auth/api_service.dart';
import '../../Auth/auth_storage.dart';
import '../../Auth/colors.dart';
import '../../l10n/app_localizations.dart';
import '../QRScannerPage.dart';
import '../../core/responsive.dart';

class StudentSessionsHistoryPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const StudentSessionsHistoryPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<StudentSessionsHistoryPage> createState() =>
      _StudentSessionsHistoryPageState();
}

class _StudentSessionsHistoryPageState extends State<StudentSessionsHistoryPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _lectures = [];
  List<dynamic> _sections = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken() ?? '';

      final lecturesResponseFuture = http.get(
        Uri.parse('${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Lecture'),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      final sectionsResponseFuture = http.get(
        Uri.parse('${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Section'),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      final results = await Future.wait([lecturesResponseFuture, sectionsResponseFuture]);
      final lecturesResponse = results[0];
      final sectionsResponse = results[1];

      if (lecturesResponse.statusCode == 200 && sectionsResponse.statusCode == 200) {
        final parsedLectures = _extractList(jsonDecode(lecturesResponse.body));
        final parsedSections = _extractList(jsonDecode(sectionsResponse.body));

        if (mounted) {
          setState(() {
            _lectures = parsedLectures.reversed.toList();
            _sections = parsedSections.reversed.toList();
            _isLoading = false;
          });
        }
        _handlePolling();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load sessions.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handlePolling() {
    final hasActive = _hasActiveSession(_lectures) || _hasActiveSession(_sections);
    if (hasActive && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchSessions());
    } else if (!hasActive && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  bool _hasActiveSession(List<dynamic> sessions) {
    for (final session in sessions) {
      if (session is Map && (session['isActive'] == true)) {
        return true;
      }
    }
    return false;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map && data.containsKey(r'$values')) {
      return data[r'$values'] ?? [];
    }
    return [];
  }

  void _openActiveSession(Map<String, dynamic> session) {
    final sessionId = session['id']?.toString() ?? session['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ActiveSessionPage(
          sessionId: sessionId,
          sessionTitle: session['title']?.toString() ?? 'Active Session',
          courseId: widget.courseId,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Error', style: const TextStyle(color: AppColors.errorColor)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchSessions,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = [..._lectures, ..._sections].where((s) => s['isActive'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        centerTitle: Responsive.isDesktop(context),
        title: Text(
          widget.courseName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.isDesktop(context) ? 22 : 18),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _errorMessage != null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentAttendanceReportPage(
                                courseName: widget.courseName,
                                lectures: _lectures,
                                sections: _sections,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics, size: 28),
                        label: Text(AppLocalizations.of(context)!.attendanceReports),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        AppLocalizations.of(context)!.registerAttendance,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRScannerPage()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 24),
                        label: Text(AppLocalizations.of(context)!.scanQrCode),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.darkColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ActiveSessionPage(
                                sessionId: activeSessions.isNotEmpty ? (activeSessions.first['id']?.toString() ?? activeSessions.first['sessionId']?.toString() ?? '0') : '0',
                                sessionTitle: activeSessions.isNotEmpty ? (activeSessions.first['title']?.toString() ?? 'Register Attendance') : 'Register Attendance',
                                courseId: widget.courseId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.pin, size: 24),
                        label: Text(AppLocalizations.of(context)!.enterPinCode),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (activeSessions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, size: 20, color: AppColors.successColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.activeSessionOpen,
                                  style: const TextStyle(color: AppColors.successColor, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ActiveGlowCard extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const _ActiveGlowCard({required this.child, required this.isActive});

  @override
  State<_ActiveGlowCard> createState() => _ActiveGlowCardState();
}

class _ActiveGlowCardState extends State<_ActiveGlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ActiveGlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.successColor.withOpacity(_animation.value),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ActiveSessionPage extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final String courseId;

  const _ActiveSessionPage({
    required this.sessionId,
    required this.sessionTitle,
    required this.courseId,
  });

  @override
  State<_ActiveSessionPage> createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends State<_ActiveSessionPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    if (_isSubmitting) return;
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userData = await AuthStorage.getUserData();
      final deviceId = userData?['deviceId'] ?? 'error_device';
      final token = await AuthStorage.getToken() ?? '';
      
      int finalSessionId = int.tryParse(widget.sessionId) ?? 0;

      if (finalSessionId == 0) {
        try {
          final lRes = await http.get(Uri.parse('${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Lecture'), headers: {'Authorization': 'Bearer $token', 'accept': '*/*'});
          final sRes = await http.get(Uri.parse('${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Section'), headers: {'Authorization': 'Bearer $token', 'accept': '*/*'});
          
          List<dynamic> extractList(dynamic data) {
            if (data is List) return data;
            if (data is Map && data.containsKey(r'$values')) return data[r'$values'] ?? [];
            return [];
          }
          
          final lectures = lRes.statusCode == 200 ? extractList(jsonDecode(lRes.body)) : [];
          final sections = sRes.statusCode == 200 ? extractList(jsonDecode(sRes.body)) : [];
          final allSessions = [...lectures, ...sections];
          
          final activeSession = allSessions.firstWhere((s) => s['isActive'] == true, orElse: () => null);
          if (activeSession != null) {
            finalSessionId = int.tryParse(activeSession['id']?.toString() ?? activeSession['sessionId']?.toString() ?? '0') ?? 0;
          }
        } catch (_) {}
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/Attendance/submit'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "sessionId": finalSessionId,
          "deviceId": deviceId,
          "studentLatitude": position.latitude,
          "studentLongitude": position.longitude,
          "scannedQrContent": null,
          "sessionPIN": pin,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.attendanceSubmitted),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(
          widget.sessionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.activeSession,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.enterPinDescription,
                    style: TextStyle(
                      color: AppColors.darkColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.enterPinTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.pinCodeLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.submitPinBtn,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class StudentAttendanceReportPage extends StatefulWidget {
  final String courseName;
  final List<dynamic> lectures;
  final List<dynamic> sections;

  const StudentAttendanceReportPage({
    Key? key,
    required this.courseName,
    required this.lectures,
    required this.sections,
  }) : super(key: key);

  @override
  State<StudentAttendanceReportPage> createState() => _StudentAttendanceReportPageState();
}

class _StudentAttendanceReportPageState extends State<StudentAttendanceReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _didAttend(dynamic session) =>
      session['isAttended'] == true || session['studentAttended'] == true || session['attended'] == true;

  Widget _buildCounterItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSessionCard(dynamic sessionData) {
    final session = Map<String, dynamic>.from(sessionData);
    final sessionId = session['id']?.toString() ?? session['sessionId']?.toString() ?? '0';
    final title = session['title'] ?? 'Session #$sessionId';
    final bool isAttended = _didAttend(session);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width >= 850 ? 24 : 16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width >= 850 ? 16 : 12),
              decoration: BoxDecoration(
                color: isAttended ? Colors.green.withOpacity(0.1) : AppColors.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAttended ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isAttended ? Colors.green : AppColors.errorColor,
                size: MediaQuery.of(context).size.width >= 850 ? 32 : 24,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width >= 850 ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width >= 850 ? 18 : 16,
                      color: AppColors.darkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: #$sessionId',
                    style: TextStyle(
                      color: AppColors.darkColor.withOpacity(0.5),
                      fontSize: MediaQuery.of(context).size.width >= 850 ? 15 : 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width >= 850 ? 14 : 10,
                vertical: MediaQuery.of(context).size.width >= 850 ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: isAttended ? Colors.green.withOpacity(0.15) : AppColors.errorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAttended ? AppLocalizations.of(context)!.attended : AppLocalizations.of(context)!.absent,
                style: TextStyle(
                  color: isAttended ? Colors.green.shade700 : AppColors.errorColor,
                  fontSize: MediaQuery.of(context).size.width >= 850 ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: AppColors.primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noSessionsFound, style: TextStyle(fontSize: 16, color: AppColors.darkColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= 900 ? 3 : w >= 600 ? 2 : 1;
      if (cols > 1) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: cols == 3 ? 2.5 : 3.0,
          ),
          itemCount: sessions.length,
          itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pastLectures = widget.lectures.where((s) => s['isActive'] != true).toList();
    final pastSections = widget.sections.where((s) => s['isActive'] != true).toList();
    final pastSessions = [...pastLectures, ...pastSections];

    final totalAttended = pastSessions.where((s) => _didAttend(s)).length;
    final totalAbsent = pastSessions.length - totalAttended;

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.attendanceReports, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: totalAbsent >= 3 ? Border.all(color: AppColors.errorColor, width: 2) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCounterItem(AppLocalizations.of(context)!.attended, totalAttended, Colors.green),
                        _buildCounterItem(AppLocalizations.of(context)!.absent, totalAbsent, AppColors.errorColor),
                        _buildCounterItem(AppLocalizations.of(context)!.totalStats, pastSessions.length, AppColors.primaryColor),
                      ],
                    ),
                    if (totalAbsent >= 3)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.errorColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.dangerYouExceededAbsenceLimit,
                                style: const TextStyle(color: AppColors.errorColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryColor,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.isDesktop(context) ? 18 : 16),
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.lecturesTab, icon: const Icon(Icons.school)),
                    Tab(text: AppLocalizations.of(context)!.sectionsTab, icon: const Icon(Icons.science)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSessionList(pastLectures),
              _buildSessionList(pastSections),
            ],
          ),
        ),
      ),
    );
  }
}
