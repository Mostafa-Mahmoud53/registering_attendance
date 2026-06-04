import 'dart:convert';
import 'package:flutter/material.dart';
import '../Auth/colors.dart';
import '../Auth/auth_storage.dart';
import '../Auth/api_service.dart';
import '../l10n/app_localizations.dart';

class ResetStudentsForNewYearPage extends StatefulWidget {
  final bool isTab;
  const ResetStudentsForNewYearPage({Key? key, this.isTab = false}) : super(key: key);
  @override
  _ResetStudentsForNewYearPageState createState() =>
      _ResetStudentsForNewYearPageState();
}

class _ResetStudentsForNewYearPageState extends State<ResetStudentsForNewYearPage> {
  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
  }

  // ── Full system reset ─────────────────────────────────────────
  Future<void> _systemReset() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context)!.authenticationTokenNotFound, AppColors.errorColor);
      return;
    }

    final ok = await _showResetConfirmDialog();
    if (!ok) return;

    if (!mounted) return;
    setState(() { _isLoading = true; _apiResponse = null; _isSuccess = false; });
    try {
      final response = await ApiService.resetSystemForNewYear(
        token: token,
      );

      final statusCode = response['statusCode'] as int;
      final responseBody = response['body'] as String;

      if (statusCode == 200) {
        String msg = AppLocalizations.of(context)!.resetSystemSuccess;
        try {
          final d = jsonDecode(responseBody);
          if (d['message'] != null) msg = '✅ ${d['message']}';
        } catch (_) {}
        
        if (!mounted) return;
        setState(() { _apiResponse = msg; _isSuccess = true; });
        _snack(msg, AppColors.successColor);
      } else {
        var errorMsg = 'Status $statusCode';
        try {
          final d = jsonDecode(responseBody);
          if (d['message'] != null) errorMsg = d['message'];
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().replaceFirst('Exception: ', '');
      setState(() { _apiResponse = AppLocalizations.of(context)!.resetSystemError(errorText); _isSuccess = false; });
      _snack(AppLocalizations.of(context)!.resetSystemError(errorText), AppColors.errorColor);
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

  Future<bool> _showResetConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.resetSystemTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.resetSystemWarning,
                      style: const TextStyle(fontSize: 14, color: AppColors.darkColor, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // What will be preserved
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.dataPreserved,
                          style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: AppColors.errorColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.dataDeleted,
                          style: TextStyle(fontSize: 13, color: AppColors.errorColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
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
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.proceedReset,
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
    return result ?? false;
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
      Icon(_isSuccess ? Icons.check_circle : Icons.error,
          color: _isSuccess ? Colors.green : Colors.red, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(_apiResponse!, style: TextStyle(color: AppColors.darkColor, fontSize: 14))),
      GestureDetector(onTap: () => setState(() => _apiResponse = null),
          child: const Icon(Icons.close, size: 14, color: Colors.grey)),
    ]),
  );

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
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40))),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(AppLocalizations.of(context)!.resetStudentsNewYear,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.errorColor, const Color(0xFFD65F51)])),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_apiResponse != null) ...[
                _buildResponseCard(),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.fullSystemReset,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.resetSystemDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.darkColor.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _systemReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: _isLoading 
                            ? const SizedBox.shrink() 
                            : const Icon(Icons.autorenew, size: 22),
                        label: _isLoading
                            ? const SizedBox(
                                width: 24, 
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                AppLocalizations.of(context)!.resetEntireSystem,
                                style: const TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
