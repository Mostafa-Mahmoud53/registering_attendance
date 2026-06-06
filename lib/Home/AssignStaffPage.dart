import 'package:flutter/material.dart';
import 'package:registering_attendance/l10n/app_localizations.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/colors.dart';
import '../Auth/api_service.dart';

class AssignStaffPage extends StatefulWidget {
  final String? initialCourseCode;
  const AssignStaffPage({super.key, this.initialCourseCode});

  @override
  _AssignStaffPageState createState() => _AssignStaffPageState();
}

class _AssignStaffPageState extends State<AssignStaffPage> {
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _staffCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseCode != null && widget.initialCourseCode!.isNotEmpty) {
      _courseCodeController.text = widget.initialCourseCode!;
    }
  }

  Future<void> _assignStaff() async {
    final courseCode = _courseCodeController.text.trim();
    final staffCode = _staffCodeController.text.trim();

    if (courseCode.isEmpty || staffCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseBothCodes), backgroundColor: AppColors.errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/Admin/assign-staff?courseCode=${Uri.encodeComponent(courseCode)}&staffUniversityCode=${Uri.encodeComponent(staffCode)}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff assigned successfully!'), backgroundColor: AppColors.successColor),
        );
        _courseCodeController.clear();
        _staffCodeController.clear();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to server'), backgroundColor: AppColors.errorColor),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.toString()}'), backgroundColor: AppColors.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.assignStaffToCourse, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.assignment_ind, size: 48, color: AppColors.primaryColor),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.assignDoctorOrTA,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the course code and the staff university code to link them together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.darkColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _courseCodeController,
                  label: AppLocalizations.of(context)!.courseCode,
                  icon: Icons.qr_code,
                  hint: AppLocalizations.of(context)!.enterCourseCode,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _staffCodeController,
                  label: AppLocalizations.of(context)!.staffUniversityCode,
                  icon: Icons.person_search,
                  hint: AppLocalizations.of(context)!.enterStaffUniversityCode,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _assignStaff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppLocalizations.of(context)!.assignStaff,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryColor, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _staffCodeController.dispose();
    super.dispose();
  }
}

