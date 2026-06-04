import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../Auth/colors.dart';
import '../Auth/auth_storage.dart';
import '../Auth/api_service.dart';
import '../widgets/AppInstructionsCard.dart';

class DeleteSingleStudentPage extends StatefulWidget {
  final bool isTab;
  const DeleteSingleStudentPage({Key? key, this.isTab = false}) : super(key: key);

  @override
  _DeleteSingleStudentPageState createState() => _DeleteSingleStudentPageState();
}

class _DeleteSingleStudentPageState extends State<DeleteSingleStudentPage> {
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _snack('University code is required', Colors.orange);
      return;
    }

    final token = await AuthStorage.getToken();
    if (token == null) {
      _snack('Authentication token not found', Colors.red);
      return;
    }

    final ok = await _showConfirm(
        'Delete Student?',
        'This permanently removes their account.\n⚠️ Cannot be undone!',
        'Delete Student');
    if (!ok) return;

    if (!mounted) return;
    setState(() { _isLoading = true; _apiResponse = null; _isSuccess = false; });
    try {
      final response = await ApiService.bulkDeleteStudents(
        codes: [code],
        token: token,
      );
      
      final statusCode = response['statusCode'] as int;
      final responseBody = response['body'] as String;

      if (statusCode == 200) {
        String msg = '✅ Student deleted successfully!';
        try { final d = jsonDecode(responseBody); if (d['message'] != null) msg = '✅ ${d['message']}'; } catch (_) {}
        
        if (!mounted) return;
        setState(() { _apiResponse = msg; _isSuccess = true; });
        _codeController.clear();
        _snack('✅ Student deleted!', Colors.green);
      } else {
        String err = 'Failed ($statusCode)';
        try { err = jsonDecode(responseBody)['message'] ?? err; } catch (_) {}
        throw Exception(err);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _apiResponse = 'Error: $e'; _isSuccess = false; });
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating));
  }

  Future<bool> _showConfirm(String title, String body, String label) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.red))),
        ]),
        content: Text(body, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(label),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(slivers: [
        if (!widget.isTab)
          SliverAppBar(
            expandedHeight: 120, collapsedHeight: 80,
            pinned: true, floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppColors.errorColor, elevation: 8,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(AppLocalizations.of(context)!.deleteSingle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.errorColor, const Color(0xFFD65F51)])),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
              AppInstructionsCard(
                title: 'How to Delete a Student',
                instructions: [
                  'Obtain the student\'s exact university code.',
                  'Enter it into the field below.',
                  'Click "Delete Student" to remove permanently.',
                ],
              ),
              const SizedBox(height: 16),

              if (_apiResponse != null) _buildResponseCard(),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('University Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkColor)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'e.g. ST-20205522',
                      hintStyle: TextStyle(color: AppColors.darkColor.withOpacity(0.35)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                      filled: true, fillColor: AppColors.lightColor2,
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.darkColor.withOpacity(0.4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(color: AppColors.darkColor, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _deleteStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_remove_alt_1, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.deleteStudentSingleBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildResponseCard() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
    ),
    child: Row(children: [
      Icon(_isSuccess ? Icons.check_circle : Icons.error, color: _isSuccess ? Colors.green : Colors.red, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(_apiResponse!, style: TextStyle(color: AppColors.darkColor, fontSize: 14))),
      GestureDetector(onTap: () => setState(() => _apiResponse = null), child: const Icon(Icons.close, size: 14, color: Colors.grey)),
    ]),
  );
}
