// ignore_for_file: avoid_print
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
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<StudentSessionsHistoryPage> createState() =>
      _StudentSessionsHistoryPageState();
}

class _StudentSessionsHistoryPageState
    extends State<StudentSessionsHistoryPage> {
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
        Uri.parse(
          '${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Lecture',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      final sectionsResponseFuture = http.get(
        Uri.parse(
          '${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Section',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      final results = await Future.wait([
        lecturesResponseFuture,
        sectionsResponseFuture,
      ]);
      final lecturesResponse = results[0];
      final sectionsResponse = results[1];

      if (lecturesResponse.statusCode == 200 &&
          sectionsResponse.statusCode == 200) {
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
    final hasActive =
        _hasActiveSession(_lectures) || _hasActiveSession(_sections);
    if (hasActive && _pollTimer == null) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => _fetchSessions(),
      );
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
    final sessionId =
        session['id']?.toString() ?? session['sessionId']?.toString() ?? '';
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error',
            style: const TextStyle(color: AppColors.errorColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchSessions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = [
      ..._lectures,
      ..._sections,
    ].where((s) => s['isActive'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        centerTitle: Responsive.isDesktop(context),
        title: Text(
          widget.courseName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.isDesktop(context) ? 22 : 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
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
                                courseId: widget.courseId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics, size: 28),
                        label: Text(
                          AppLocalizations.of(context)!.attendanceReports,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Register Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QRScannerPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 24),
                        label: Text(AppLocalizations.of(context)!.scanQrCode),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.darkColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ActiveSessionPage(
                                sessionId: activeSessions.isNotEmpty
                                    ? (activeSessions.first['id']?.toString() ??
                                          activeSessions.first['sessionId']
                                              ?.toString() ??
                                          '0')
                                    : '0',
                                sessionTitle: activeSessions.isNotEmpty
                                    ? (activeSessions.first['title']
                                              ?.toString() ??
                                          'Register Attendance')
                                    : 'Register Attendance',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (activeSessions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.successColor,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'An active session is open!',
                                  style: TextStyle(
                                    color: AppColors.successColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                color: AppColors.successColor.withValues(
                  alpha: _animation.value,
                ),
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
          final lRes = await http.get(
            Uri.parse(
              '${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Lecture',
            ),
            headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
          );
          final sRes = await http.get(
            Uri.parse(
              '${ApiService.baseUrl}/Session/course-sessions/${widget.courseId}/Section',
            ),
            headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
          );

          List<dynamic> extractList(dynamic data) {
            if (data is List) return data;
            if (data is Map && data.containsKey(r'$values'))
              return data[r'$values'] ?? [];
            return [];
          }

          final lectures = lRes.statusCode == 200
              ? extractList(jsonDecode(lRes.body))
              : [];
          final sections = sRes.statusCode == 200
              ? extractList(jsonDecode(sRes.body))
              : [];
          final allSessions = [...lectures, ...sections];

          final activeSession = allSessions.firstWhere(
            (s) => s['isActive'] == true,
            orElse: () => null,
          );
          if (activeSession != null) {
            finalSessionId =
                int.tryParse(
                  activeSession['id']?.toString() ??
                      activeSession['sessionId']?.toString() ??
                      '0',
                ) ??
                0;
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
          const SnackBar(
            content: Text('Attendance submitted!'),
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
                      const Text(
                        'Active Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please enter the 4-digit PIN provided by the Doctor to register your attendance.',
                        style: TextStyle(
                          color: AppColors.darkColor.withValues(alpha: 0.6),
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
                      const Text(
                        'Enter PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'PIN Code',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryColor,
                                width: 2,
                              ),
                            ),
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
                              : const Text(
                                  'Submit PIN',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class StudentAttendanceReportPage extends StatefulWidget {
  final String courseName;
  final String courseId;

  const StudentAttendanceReportPage({
    super.key,
    required this.courseName,
    required this.courseId,
  });

  @override
  State<StudentAttendanceReportPage> createState() =>
      _StudentAttendanceReportPageState();
}

class _StudentAttendanceReportPageState
    extends State<StudentAttendanceReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _lectures = [];
  List<dynamic> _sections = [];
  String _rawJson = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchMyHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken() ?? '';
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/Attendance/my-history/${widget.courseId}',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        _rawJson = response.body;
        final decoded = jsonDecode(response.body);
        print('my-history raw response: $decoded');

        List<dynamic> lectures = [];
        List<dynamic> sections = [];

        if (decoded is Map) {
          // Check for the new JSON structure: { "lecturesData": { "history": [...] }, "sectionsData": { ... } }
          if (decoded.containsKey('lecturesData') ||
              decoded.containsKey('sectionsData')) {
            final lecData = decoded['lecturesData'] ?? {};
            final secData = decoded['sectionsData'] ?? {};
            lectures = _extractList(lecData['history'] ?? []);
            sections = _extractList(secData['history'] ?? []);
          } else {
            // Fallback for older shapes
            lectures = _extractList(
              decoded['lectures'] ??
                  decoded['Lectures'] ??
                  decoded['lectureHistory'] ??
                  [],
            );
            sections = _extractList(
              decoded['sections'] ??
                  decoded['Sections'] ??
                  decoded['sectionHistory'] ??
                  [],
            );
          }

          // If the API returns a flat list, separate by type
          if (lectures.isEmpty && sections.isEmpty) {
            final allSessions = _extractList(
              decoded[r'$values'] ??
                  decoded['sessions'] ??
                  decoded['data'] ??
                  decoded['history'] ??
                  [],
            );
            if (allSessions.isEmpty && decoded.keys.length <= 3) {
              // Maybe the whole response IS a flat list wrapper
              final flatList = _extractList(decoded);
              for (final s in flatList) {
                if (s is Map) {
                  final type = (s['type'] ?? s['sessionType'] ?? '')
                      .toString()
                      .toLowerCase();
                  if (type.contains('section')) {
                    sections.add(s);
                  } else {
                    lectures.add(s);
                  }
                }
              }
            } else {
              for (final s in allSessions) {
                if (s is Map) {
                  final type = (s['type'] ?? s['sessionType'] ?? '')
                      .toString()
                      .toLowerCase();
                  if (type.contains('section')) {
                    sections.add(s);
                  } else {
                    lectures.add(s);
                  }
                }
              }
            }
          }
        } else if (decoded is List) {
          // Flat list response — separate by type
          for (final s in decoded) {
            if (s is Map) {
              final type = (s['type'] ?? s['sessionType'] ?? '')
                  .toString()
                  .toLowerCase();
              if (type.contains('section')) {
                sections.add(s);
              } else {
                lectures.add(s);
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _lectures = lectures;
            _sections = sections;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load attendance history (${response.statusCode})';
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

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey(r'$values'))
      return data[r'$values'] ?? [];
    return [];
  }

  bool _didAttend(dynamic session) {
    if (session is! Map) return false;
    // Check all possible boolean field names from the API
    final attended =
        session['isAttended'] ??
        session['studentAttended'] ??
        session['attended'] ??
        session['IsAttended'] ??
        session['Attended'];
    if (attended is bool) return attended;
    if (attended is String) return attended.toLowerCase() == 'true';
    return false;
  }

  Widget _buildCounterItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(dynamic sessionData) {
    final session = Map<String, dynamic>.from(sessionData);
    final sessionId =
        session['id']?.toString() ??
        session['sessionId']?.toString() ??
        session['SessionId']?.toString() ??
        '0';
    final fallbackSessionName =
        session['sessionName'] ?? session['SessionName'];
    final titleStr =
        session['title']?.toString() ??
        session['Title']?.toString() ??
        session['sessionTitle']?.toString() ??
        session['SessionTitle']?.toString() ??
        session['name']?.toString() ??
        session['Name']?.toString() ??
        (fallbackSessionName != null &&
                !fallbackSessionName.toString().startsWith('Lecture') &&
                !fallbackSessionName.toString().startsWith('Section')
            ? fallbackSessionName.toString()
            : null) ??
        fallbackSessionName?.toString() ??
        'Session #$sessionId';

    final title = titleStr.isNotEmpty ? titleStr : 'Session #$sessionId';
    final bool isAttended = _didAttend(session);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width >= 850 ? 24 : 16.0,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width >= 850 ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: isAttended
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppColors.errorColor.withValues(alpha: 0.1),
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
                      fontSize: MediaQuery.of(context).size.width >= 850
                          ? 18
                          : 16,
                      color: AppColors.darkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: #$sessionId',
                    style: TextStyle(
                      color: AppColors.darkColor.withValues(alpha: 0.5),
                      fontSize: MediaQuery.of(context).size.width >= 850
                          ? 15
                          : 13,
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
                color: isAttended
                    ? Colors.green.withValues(alpha: 0.15)
                    : AppColors.errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAttended ? 'Attended' : 'Absent',
                style: TextStyle(
                  color: isAttended
                      ? Colors.green.shade700
                      : AppColors.errorColor,
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
            Icon(
              Icons.history_toggle_off,
              size: 60,
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions found.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1100
            ? 4
            : w >= 850
            ? 3
            : w >= 600
            ? 2
            : 1;
        if (cols > 1) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              mainAxisExtent: 100,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          title: const Text(
            'Attendance Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.lightColor2,
        appBar: AppBar(
          title: const Text(
            'Attendance Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
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
                _errorMessage!,
                style: const TextStyle(color: AppColors.errorColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMyHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pastLectures = _lectures;
    final pastSections = _sections;

    final lecturesAttended = pastLectures.where((s) => _didAttend(s)).length;
    final lecturesAbsent = pastLectures.length - lecturesAttended;

    final sectionsAttended = pastSections.where((s) => _didAttend(s)).length;
    final sectionsAbsent = pastSections.length - sectionsAttended;

    Widget buildStatsCard(String title, int attended, int absent, int total) {
      final bool isDanger = title == 'Lectures' && absent >= 3;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDanger
              ? Border.all(color: AppColors.errorColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounterItem('Attended', attended, Colors.green),
                _buildCounterItem('Absent', absent, AppColors.errorColor),
                _buildCounterItem('Total', total, AppColors.primaryColor),
              ],
            ),
            if (isDanger)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.errorColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Danger: You have exceeded the allowed absence limit (3) and may be deprived of exams.',
                        style: TextStyle(
                          color: AppColors.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  if (_tabController.index == 0)
                    buildStatsCard(
                      'Lectures',
                      lecturesAttended,
                      lecturesAbsent,
                      pastLectures.length,
                    )
                  else
                    buildStatsCard(
                      'Sections',
                      sectionsAttended,
                      sectionsAbsent,
                      pastSections.length,
                    ),
                  const SizedBox(height: 8),
                ],
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
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.isDesktop(context) ? 18 : 16,
                  ),
                  tabs: const [
                    Tab(text: 'Lectures', icon: Icon(Icons.school)),
                    Tab(text: 'Sections', icon: Icon(Icons.science)),
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
