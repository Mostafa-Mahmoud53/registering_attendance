import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../Auth/auth_storage.dart';
import '../Auth/colors.dart';
import '../widgets/app_instructions_card.dart';

class EnrollMultiplePage extends StatefulWidget {
  final String courseId;
  final bool isTab;
  const EnrollMultiplePage({super.key, required this.courseId, this.isTab = false});

  @override
  _EnrollMultiplePageState createState() => _EnrollMultiplePageState();
}

class _EnrollMultiplePageState extends State<EnrollMultiplePage> {
  final TextEditingController _manualCodeController = TextEditingController();
  final List<String> _codesList = [];
  bool _isLoading = false;

  static const String _apiUrl = 'http://77.83.242.94:5000/api/Course/enroll-bulk';

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  void _addManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    if (_codesList.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Code "$code" already in list'), backgroundColor: Colors.orange));
      return;
    }
    setState(() {
      _codesList.add(code);
      _manualCodeController.clear();
    });
  }

  Future<void> _enrollAll() async {
    if (_codesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.universityCodeHint),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.authenticationTokenNotFound),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final courseId = int.parse(widget.courseId);
      final enrollmentData = {
        "courseId": courseId,
        "studentCodes": _codesList,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(enrollmentData),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 207) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _codesList.clear();
        });

        _showResultDialog(
          responseData['added'] != null ? List<String>.from(responseData['added']) : [],
          responseData['skipped'] != null ? List<String>.from(responseData['skipped']) : [],
          responseData['notFound'] != null ? List<String>.from(responseData['notFound']) : [],
          responseData['message'] ?? 'Enrollment process completed',
        );
      } else {
        String errorMsg = 'Failed to enroll students';
        try {
          final data = jsonDecode(response.body);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(List<String> added, List<String> skipped, List<String> notFound, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.enrolledStudents, style: TextStyle(color: AppColors.darkColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty) Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (added.isNotEmpty) ...[
                  const Text('Added successfully:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: added.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.green.withValues(alpha: 0.2))).toList()),
                  const SizedBox(height: 10),
                ],
                if (skipped.isNotEmpty) ...[
                  const Text('Skipped (Already Enrolled):', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: skipped.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.orange.withValues(alpha: 0.2))).toList()),
                  const SizedBox(height: 10),
                ],
                if (notFound.isNotEmpty) ...[
                  const Text('Not Found:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, children: notFound.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12, color: Colors.white)), backgroundColor: Colors.red)).toList()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManualCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.addStudentsBulkSubtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
          const SizedBox(height: 16),
          TextField(
            controller: _manualCodeController,
            decoration: InputDecoration(
              labelText: loc.studentCode,
              hintText: loc.universityCodeHint,
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _manualCodeController.clear(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.errorColor),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.clearBtn, style: TextStyle(color: AppColors.errorColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addManualCode,
                  icon: const Icon(Icons.add),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.addBtn),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodesListCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Added Codes (${_codesList.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _codesList.asMap().entries.map((entry) {
              final index = entry.key;
              final code = entry.value;
              return Chip(
                label: Text(code),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _codesList.removeAt(index);
                  });
                },
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(
        slivers: [
          if (!widget.isTab)
            SliverAppBar(
              expandedHeight: 120,
              collapsedHeight: 80,
              pinned: true,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: AppColors.primaryColor,
              elevation: 8,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(loc.enrollMultiple, style: const TextStyle(color: Colors.white, fontSize: 18)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryColor, AppColors.darkColor]),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppInstructionsCard(
                    title: 'How to Enroll Multiple Students',
                    instructions: [
                      'Enter each student code.',
                      'Click Add to add to the list.',
                      'Click Enroll All when done.',
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildManualCard(loc),
                  const SizedBox(height: 16),

                  if (_codesList.isNotEmpty) ...[
                    _buildCodesListCard(),
                    const SizedBox(height: 24),

                    // Enroll All Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _enrollAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.group_add, size: 20),
                                  const SizedBox(width: 8),
                                  Text(loc.enrollAll, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
