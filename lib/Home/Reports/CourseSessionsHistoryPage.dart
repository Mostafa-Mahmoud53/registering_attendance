import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../../Auth/colors.dart';
import '../../Auth/api_service.dart';
import '../../Auth/auth_storage.dart';
import '../../l10n/app_localizations.dart';
import 'SessionAttendeesPage.dart';

class CourseSessionsHistoryPage extends StatefulWidget {
  final String courseId;

  const CourseSessionsHistoryPage({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseSessionsHistoryPage> createState() => _CourseSessionsHistoryPageState();
}

class _CourseSessionsHistoryPageState extends State<CourseSessionsHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _lectures = [];
  List<dynamic> _sections = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        
        setState(() {
          _lectures = parsedLectures.reversed.toList();
          _sections = parsedSections.reversed.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load sessions. Server returned code ${lecturesResponse.statusCode}.';
          _isLoading = false;
        });
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
    if (data is List) {
      return data;
    } else if (data is Map && data.containsKey('\$values')) {
      return data['\$values'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sessionHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.lecturesTab, icon: const Icon(Icons.school)),
            Tab(text: AppLocalizations.of(context)!.sectionsTab, icon: const Icon(Icons.science)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionList(_lectures, 'Lecture'),
                    _buildSessionList(_sections, 'Section'),
                  ],
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
          Text(_errorMessage!, style: const TextStyle(color: AppColors.errorColor)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchSessions,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<dynamic> sessions, String type) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.indigo.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noSessionsFound,
              style: TextStyle(fontSize: 18, color: Colors.indigo.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cols = w >= 1100 ? 4 : w >= 850 ? 3 : w >= 600 ? 2 : 1;
          final isMobile = w < 600;
          if (cols > 1) {
            return GridView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: isMobile ? 8 : 12,
                crossAxisSpacing: isMobile ? 8 : 12,
                mainAxisExtent: 95,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) => _buildSessionCard(sessions[index], type, sessions, isMobile: isMobile),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) => _buildSessionCard(sessions[index], type, sessions, isMobile: isMobile),
          );
        }),
      ),
    );
  }

  Widget _buildSessionCard(dynamic session, String type, List<dynamic> sessionsList, {bool isMobile = false}) {
    final sessionId = session['id']?.toString() ?? session['sessionId']?.toString() ?? '0';
    final title = session['title'] ?? '$type #$sessionId';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionAttendeesPage(
                sessionId: sessionId,
                sessionTitle: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.class_,
                  color: Colors.indigo,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
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
                        fontSize: isMobile ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.errorColor,
                  size: isMobile ? 20 : 22,
                ),
                tooltip: AppLocalizations.of(context)!.deleteSession,
                onPressed: () => _showDeleteConfirmation(sessionId, title, sessionsList),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              Icon(
                Icons.arrow_forward_ios,
                size: isMobile ? 14 : 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a session
  void _showDeleteConfirmation(String sessionId, String sessionTitle, List<dynamic> sessionsList) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: AppColors.errorColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.deleteSession,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        sessionTitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Text(
                AppLocalizations.of(context)!.deleteSessionWarning,
                style: const TextStyle(fontSize: 15, color: AppColors.darkColor),
                textAlign: TextAlign.center,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setDialogState(() => isDeleting = true);

                                try {
                                  final token = await AuthStorage.getToken() ?? '';
                                  final result = await ApiService.deleteSession(
                                    sessionId: sessionId,
                                    token: token,
                                  );

                                  if (!mounted) return;

                                  if (result['statusCode'] == 200) {
                                    Navigator.pop(dialogContext);

                                    // Remove from local list immediately
                                    setState(() {
                                      sessionsList.removeWhere((s) {
                                        final id = s['id']?.toString() ?? s['sessionId']?.toString() ?? '';
                                        return id == sessionId;
                                      });
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppLocalizations.of(context)!.sessionDeletedSuccessfully),
                                        backgroundColor: AppColors.successColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setDialogState(() => isDeleting = false);
                                    var errorMsg = result['body']?.toString() ?? 'Unknown error';
                                    try {
                                      final data = jsonDecode(result['body']);
                                      if (data is Map && data['message'] != null) {
                                        errorMsg = data['message'];
                                      }
                                    } catch (_) {}

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppLocalizations.of(context)!.deleteSessionError(errorMsg)),
                                        backgroundColor: AppColors.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isDeleting = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.deleteSessionError(e.toString())),
                                      backgroundColor: AppColors.errorColor,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.delete,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
