import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:registering_attendance/core/http_interceptor.dart' as http;
import '../../Auth/colors.dart';
import '../../Auth/api_service.dart';
import '../../Auth/auth_storage.dart';
import '../../features/session/session_models.dart';
import '../../l10n/app_localizations.dart';
import 'LiveDashboardPage.dart';

class CreateSessionPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CreateSessionPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  
  String _sessionType = 'Lecture';
  double _radius = 200.0; // Increased to 200m default for testing
  bool _isLoading = false;

  Future<void> _createSession() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Check GPS Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(loc.locationPermissionsDenied);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(loc.locationPermissionsPermanentlyDenied);
      }

      // 2. Fetch User Location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Make the API Call
      final token = await AuthStorage.getToken() ?? '';
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/Session/create'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "courseId": int.parse(widget.courseId),
          "title": _titleController.text.trim(),
          "sessionType": _sessionType,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "allowRadius": _radius.toInt(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsedJson = jsonDecode(response.body);
        // Sometimes APIs wrap the data in a 'data' object.
        final responseData = parsedJson['data'] ?? parsedJson;
        final resObj = CreateSessionResponse.fromJson(responseData);
        
        if (resObj.sessionId == 0) {
          throw Exception('Backend returned invalid session ID');
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LiveDashboardPage(
                sessionId: resObj.sessionId,
                courseName: widget.courseName, 
                initialQr: resObj.qrContent,
                initialPin: resObj.pinCode,
                isResumed: resObj.isResumed,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.somethingWentWrong}: ${response.body}'), backgroundColor: AppColors.errorColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.somethingWentWrong}: ${e.toString()}'), backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      appBar: AppBar(
        title: Text(loc.createSession, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return SingleChildScrollView(
                // Mobile Layout: reduced padding / Desktop Layout: standard padding
                padding: isMobile
                    ? const EdgeInsets.all(16)       // Mobile Layout
                    : const EdgeInsets.all(24),      // Desktop Layout
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Course Information Card ──────────────────────────────
                      Container(
                        // Mobile Layout: compact padding / Desktop Layout: standard padding
                        padding: isMobile
                            ? const EdgeInsets.all(12)  // Mobile Layout
                            : const EdgeInsets.all(16), // Desktop Layout
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.school, color: Colors.indigo),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.course, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(
                                    widget.courseName,
                                    // Mobile Layout: smaller font / Desktop Layout: standard font
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 18, // Mobile: 15 / Desktop: 18
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 32), // Mobile: 20 / Desktop: 32

                      // ── Session Title ────────────────────────────────────────
                      Text(
                        loc.sessionTitle,
                        // Mobile Layout: smaller label / Desktop Layout: standard label
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16, // Mobile: 14 / Desktop: 16
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: loc.enterSessionTitle,
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.title, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.isEmpty ? loc.pleaseFixErrorsForm : null,
                      ),
                      SizedBox(height: isMobile ? 16 : 24), // Mobile: 16 / Desktop: 24

                      // ── Session Type ─────────────────────────────────────────
                      Text(
                        loc.sessionType,
                        // Mobile Layout: smaller label / Desktop Layout: standard label
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16, // Mobile: 14 / Desktop: 16
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sessionType,
                            isExpanded: true,
                            items: ['Lecture', 'Section'].map((type) {
                              final label = type == 'Lecture' ? loc.lecture : loc.section;
                              return DropdownMenuItem(value: type, child: Text(label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _sessionType = val);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24), // Mobile: 16 / Desktop: 24

                      // ── Geofencing Radius ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.allowedRadius,
                            // Mobile Layout: smaller label / Desktop Layout: standard label
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16, // Mobile: 14 / Desktop: 16
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              // Mobile Layout: compact chip / Desktop Layout: standard chip
                              horizontal: isMobile ? 10 : 12, // Mobile: 10 / Desktop: 12
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              loc.meters(_radius.toInt()),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 12 : 14, // Mobile: 12 / Desktop: 14
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.indigo,
                          inactiveTrackColor: Colors.indigo.withOpacity(0.2),
                          thumbColor: Colors.indigo,
                          overlayColor: Colors.indigo.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: _radius,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          onChanged: (val) => setState(() => _radius = val),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 32), // Mobile: 20 / Desktop: 32

                      // ── Launch Button ────────────────────────────────────────
                      Container(
                        // Mobile Layout: smaller height / Desktop Layout: standard height
                        height: isMobile ? 48 : 56, // Mobile: 48 / Desktop: 56
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.rocket_launch, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      loc.startSession,
                                      // Mobile Layout: smaller text / Desktop Layout: standard text
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 15 : 18, // Mobile: 15 / Desktop: 18
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
