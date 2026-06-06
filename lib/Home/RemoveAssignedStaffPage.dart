import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../Auth/auth_storage.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';

class RemoveAssignedStaffPage extends StatefulWidget {
  final int courseId;
  final String courseCode;

  const RemoveAssignedStaffPage({
    super.key,
    required this.courseId,
    required this.courseCode,
  });

  @override
  _RemoveAssignedStaffPageState createState() => _RemoveAssignedStaffPageState();
}

class _RemoveAssignedStaffPageState extends State<RemoveAssignedStaffPage> {
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _rawBody;
  int? _removingIndex; // index of item currently being removed

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _rawBody = null;
    });

    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.authenticationTokenNotFound;
      });
      return;
    }

    try {
      final result = await ApiService.getAssignedStaff(
        courseCode: widget.courseCode,
        token: token,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        final body = result['body'] as String;
        _rawBody = body;
        var decoded = jsonDecode(body);

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey(r'$values')) {
            rawList = decoded[r'$values'] ?? [];
          } else {
            // Find the first value that is a List
            for (var value in decoded.values) {
              if (value is List) {
                rawList = value;
                break;
              }
            }
            // If still empty, maybe the raw body is empty or doesn't contain a list
          }
        }

        setState(() {
          _staffList = rawList.map<Map<String, dynamic>>((item) {
            return {
              'name': item['name'] ?? item['fullName'] ?? item['userName'] ?? 'Unknown',
              'universityCode': item['universityCode'] ?? item['code'] ?? '',
              'role': item['role'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.errorLoadingStaff;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.errorLoadingStaff;
      });
    }
  }

  Future<void> _removeStaff(int index) async {
    final staff = _staffList[index];
    final staffName = staff['name'] ?? 'Unknown';
    final staffCode = staff['universityCode'] ?? '';
    final loc = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
                child: const Icon(Icons.person_remove, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                loc.removeAssignedStaff,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Text(
          loc.confirmRemoveStaff(staffName),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.darkColor),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(loc.cancel, style: TextStyle(color: Colors.grey.shade600)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(loc.remove, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Proceed with removal
    setState(() => _removingIndex = index);

    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _removingIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.authenticationTokenNotFound),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final result = await ApiService.removeStaff(
        courseCode: widget.courseCode,
        staffUniversityCode: staffCode,
        token: token,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        setState(() {
          _staffList.removeAt(index);
          _removingIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.staffRemovedSuccess),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _removingIndex = null);
        var errorMsg = 'Failed to remove staff';
        try {
          final data = jsonDecode(result['body']);
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _removingIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(
          loc.removeAssignedStaff,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.errorColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Text(loc.loadingStaff, style: TextStyle(color: AppColors.darkColor.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.errorColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchStaff,
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_staffList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: AppColors.darkColor.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                loc.noStaffAssigned,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.darkColor.withValues(alpha: 0.5)),
              ),

            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStaff,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staffList.length,
        itemBuilder: (context, index) {
          final staff = _staffList[index];
          final isRemoving = _removingIndex == index;
          final String name = staff['name'] ?? 'Unknown';
          final String code = staff['universityCode'] ?? '';
          final String role = staff['role'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkColor,
                            ),
                          ),
                          if (code.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              code,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (role.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: role.toLowerCase().contains('doctor')
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: role.toLowerCase().contains('doctor')
                                      ? Colors.blue
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Remove button
                    isRemoving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.errorColor,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorColor),
                            onPressed: () => _removeStaff(index),
                            tooltip: loc.remove,
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
