import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../Auth/colors.dart';
import '../Auth/auth_storage.dart';
import '../Auth/api_service.dart';
import '../widgets/AppInstructionsCard.dart';

class DeleteMultipleStudentsPage extends StatefulWidget {
  final bool isTab;
  const DeleteMultipleStudentsPage({Key? key, this.isTab = false}) : super(key: key);

  @override
  _DeleteMultipleStudentsPageState createState() => _DeleteMultipleStudentsPageState();
}

class _DeleteMultipleStudentsPageState extends State<DeleteMultipleStudentsPage> {
  final TextEditingController _manualCodeController = TextEditingController();

  bool _isLoading = false;
  String? _apiResponse;
  bool _isSuccess = false;
  List<String> _codesList = [];

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  void _addManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    if (_codesList.contains(code)) {
      _snack('Code "$code" already in list', Colors.orange);
      return;
    }
    setState(() {
      _codesList.add(code);
      _manualCodeController.clear();
    });
  }

  void _clearAll() {
    setState(() {
      _codesList.clear();
      _manualCodeController.clear();
      _apiResponse = null;
      _isSuccess = false;
    });
  }

  Future<void> _deleteStudents() async {
    if (_codesList.isEmpty) { _snack('Add codes first', Colors.orange); return; }
    
    final token = await AuthStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      _snack('Authentication token not found', Colors.red);
      return;
    }

    final ok = await _showConfirm(
        'Delete ${_codesList.length} students?',
        'This permanently removes their accounts.\n⚠️ Cannot be undone!',
        'Delete ${_codesList.length} Students');
    if (!ok) return;

    if (!mounted) return;
    setState(() { _isLoading = true; _apiResponse = null; _isSuccess = false; });
    try {
      final response = await ApiService.bulkDeleteStudents(
        codes: _codesList,
        token: token,
      );
      
      final statusCode = response['statusCode'] as int;
      final responseBody = response['body'] as String;

      if (statusCode == 200) {
        final count = _codesList.length;
        String msg = '✅ $count student(s) deleted successfully!';
        try { final d = jsonDecode(responseBody); if (d['message'] != null) msg = '✅ ${d['message']}'; } catch (_) {}
        
        if (!mounted) return;
        setState(() { _apiResponse = msg; _isSuccess = true; });
        _codesList.clear();
        _snack('✅ $count student(s) deleted!', Colors.green);
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
              title: Text(AppLocalizations.of(context)!.deleteMultiple, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                title: 'How to Delete Multiple Students',
                instructions: [
                  AppLocalizations.of(context)!.deleteOption2,
                  AppLocalizations.of(context)!.deleteOption3,
                  AppLocalizations.of(context)!.deleteOption4,
                  AppLocalizations.of(context)!.deleteOption5,
                ],
              ),
              const SizedBox(height: 16),

              if (_apiResponse != null) _buildResponseCard(),
              const SizedBox(height: 16),

              _buildManualCard(),
              const SizedBox(height: 16),

              if (_codesList.isNotEmpty) ...[
                _buildCodesListCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deleteStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Delete ${_codesList.length} Student${_codesList.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
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

  Widget _buildManualCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.addManually, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
      const SizedBox(height: 8),
      Text(AppLocalizations.of(context)!.enterCodeAndPressAdd, style: TextStyle(fontSize: 13, color: AppColors.darkColor.withOpacity(0.6))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _manualCodeController,
            onFieldSubmitted: (_) => _addManualCode(),
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
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _addManualCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(AppLocalizations.of(context)!.addBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _clearAll,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(AppLocalizations.of(context)!.clearAll),
      ),
    ]),
  );

  Widget _buildCodesListCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Students to Delete (${_codesList.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkColor)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
          ),
          child: const Text('Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
        ),
      ]),
      const SizedBox(height: 16),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _codesList.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightColor2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)))),
            const SizedBox(width: 12),
            Expanded(child: Text(_codesList[i], style: TextStyle(color: AppColors.darkColor, fontWeight: FontWeight.w500))),
            GestureDetector(
              onTap: () => setState(() => _codesList.removeAt(i)),
              child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
          ]),
        ),
      ),
    ]),
  );
}
