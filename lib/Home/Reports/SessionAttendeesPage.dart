import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../../Auth/colors.dart';
import '../../Auth/api_service.dart';
import '../../Auth/auth_storage.dart';

class SessionAttendeesPage extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const SessionAttendeesPage({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<SessionAttendeesPage> createState() => _SessionAttendeesPageState();
}

class _SessionAttendeesPageState extends State<SessionAttendeesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  List<dynamic> _attendees = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetch();
  }

  Future<void> _checkRoleAndFetch() async {
    final userData = await AuthStorage.getUserData();
    _userRole = userData?['role'];
    _fetchAttendees();
  }

  Future<void> _fetchAttendees() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken() ?? '';
      String url = '${ApiService.baseUrl}/Attendance/session-attendees/${widget.sessionId}';
      if (_searchQuery.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(_searchQuery)}';
      }

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listData = [];
        
        if (decoded is List) {
          listData = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('\$values')) {
            listData = decoded['\$values'];
          } else if (decoded.containsKey('attendees')) {
             var att = decoded['attendees'];
             listData = att is List ? att : (att is Map && att.containsKey('\$values') ? att['\$values'] : []);
          } else if (decoded.containsKey('students')) {
             var stu = decoded['students'];
             listData = stu is List ? stu : (stu is Map && stu.containsKey('\$values') ? stu['\$values'] : []);
          } else if (decoded.containsKey('data')) {
             var dat = decoded['data'];
             listData = dat is List ? dat : (dat is Map && dat.containsKey('\$values') ? dat['\$values'] : []);
          }
        }

        if (mounted) {
          setState(() {
            _attendees = List.from(listData);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load attendees: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAttendance(dynamic studentId) async {
    final token = await AuthStorage.getToken() ?? '';
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/Attendance/delete/${widget.sessionId}/$studentId'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance deleted successfully'), backgroundColor: AppColors.successColor),
        );
        _fetchAttendees();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}'), backgroundColor: AppColors.errorColor),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server'), backgroundColor: AppColors.errorColor),
      );
    }
  }

  Future<void> _showManualAddDialog() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isAdding = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Manual Attendance'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Enter the student\'s University Code to record attendance manually:'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'University Code',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.pin),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter code' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() => isAdding = true);
                            final token = await AuthStorage.getToken() ?? '';
                            try {
                              final response = await http.post(
                                Uri.parse('${ApiService.baseUrl}/Attendance/manual-add'),
                                headers: {
                                  'accept': '*/*',
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  "sessionId": int.parse(widget.sessionId),
                                  "studentUniversityCode": codeController.text.trim()
                                }),
                              );
                              if (response.statusCode == 200) {
                                Navigator.pop(context);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Student added successfully'), backgroundColor: AppColors.successColor),
                                );
                                _fetchAttendees();
                              } else {
                                setStateDialog(() => isAdding = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${response.body}'), backgroundColor: AppColors.errorColor),
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isAdding = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Network error'), backgroundColor: AppColors.errorColor),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: isAdding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Student', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canManage = _userRole == 'Doctor' || _userRole == 'TA' || _userRole == 'Admin';

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(widget.sessionTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showManualAddDialog,
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Manual Add', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
        children: [
          Container(
            color: Colors.indigo,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.white70),
                  hintText: 'Search by name or code...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _fetchAttendees();
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                onSubmitted: (val) {
                  _fetchAttendees();
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            TextButton(onPressed: _fetchAttendees, child: const Text('Try Again')),
                          ],
                        ),
                      )
                    : _attendees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text('No students attended yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          )
                        : LayoutBuilder(builder: (context, constraints) {
                            final cols = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 850 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
                            if (cols > 1) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 95,
                                ),
                                itemCount: _attendees.length,
                                itemBuilder: (context, index) {
                                  final student = _attendees[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                        child: const Icon(Icons.person, color: Colors.indigo),
                                      ),
                                      title: Text(student['studentName'] ?? student['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(student['universityCode'] ?? student['code'] ?? ''),
                                      trailing: canManage
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                              onPressed: () async {
                                                bool? confirm = await showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Attendance'),
                                                    content: const Text('Remove this student?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  final code = student['universityCode'] ?? student['code'];
                                                  if (code != null) _deleteAttendance(code);
                                                }
                                              },
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _attendees.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final student = _attendees[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                      child: const Icon(Icons.person, color: Colors.indigo),
                                    ),
                                    title: Text(student['studentName'] ?? student['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(student['universityCode'] ?? student['code'] ?? ''),
                                    trailing: canManage
                                        ? IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () async {
                                              bool? confirm = await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete Attendance'),
                                                  content: const Text('Are you sure you want to remove this student?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                final universityCode = student['universityCode'] ?? student['code'];
                                                if (universityCode != null) {
                                                  _deleteAttendance(universityCode);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Error: Student University Code not found'), backgroundColor: Colors.red),
                                                  );
                                                }
                                              }
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              },
                            );
                          }),
          ),
        ],
      ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
