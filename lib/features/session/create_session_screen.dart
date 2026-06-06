// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'session_models.dart';
import 'session_service.dart';
import 'qr_display_screen.dart';
import '../../Auth/colors.dart';

class CreateSessionScreen extends StatefulWidget {
  final int courseId;

  const CreateSessionScreen({super.key, required this.courseId});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '50');
  
  String _sessionType = 'Lecture';
  final List<String> _sessionTypes = ['Lecture', 'Section'];
  
  double? _latitude;
  double? _longitude;
  
  bool _isLoading = false;
  bool _isGpsReady = false;
  bool _isGpsFailed = false;

  @override
  void initState() {
    super.initState();
    _initGps();
  }
  
  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isGpsFailed = true;
        });
        print('GPS unavailable: Service disabled');
        return;
      }
      
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isGpsReady = true;
          _isGpsFailed = false;
        });
        print('GPS: $_latitude, $_longitude');
      } else {
        setState(() {
          _isGpsFailed = true;
        });
        print('GPS unavailable: Permission not granted');
      }
    } catch (e) {
       setState(() {
        _isGpsFailed = true;
      });
      print('GPS unavailable: $e');
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Session title is required';
    }
    return null;
  }
  
  String? _validateRadius(String? value) {
    if (value == null || value.isEmpty) {
      return 'Radius is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  Future<void> _startSession() async {
    if (_isLoading) return; // Prevent double taps
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final title = _titleController.text.trim();
    int radius = int.parse(_radiusController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      print('Creating session for courseId: ${widget.courseId}');
      
      final dto = CreateSessionDto(
        courseId: widget.courseId,
        title: title,
        sessionType: _sessionType,
        latitude: _latitude,
        longitude: _longitude,
        allowRadius: radius,
      );

      final service = SessionService();
      final result = await service.createSession(dto);
      
      print('Response sessionId: ${result.sessionId}');
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QrDisplayScreen(
            sessionId: result.sessionId,
            initialQrContent: result.qrContent,
            initialPinCode: result.pinCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorString = e.toString();
      if (errorString.contains('activeSessionId')) {
        final match = RegExp(r'activeSessionId["\s:]*(\d+)').firstMatch(errorString);
        int? activeId;
        if (match != null) {
          activeId = int.tryParse(match.group(1)!);
        }

        if (activeId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.sessionAlreadyRunning, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(AppLocalizations.of(context)!.sessionAlreadyRunning),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    print('Resuming session: $activeId');
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      final response = await SessionService().resumeSession(activeId!);
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrDisplayScreen(
                            sessionId: activeId!,
                            initialQrContent: response.qrContent,
                            initialPinCode: response.pinCode,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error resuming session: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.continueAction, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return; // Skip showing the generic error snackbar
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.darkColor.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                prefixIcon,
                color: AppColors.darkColor.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              color: AppColors.darkColor,
              fontSize: 16,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _sessionType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.class_,
                color: AppColors.darkColor.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.darkColor.withValues(alpha: 0.7)),
            style: const TextStyle(
              color: AppColors.darkColor,
              fontSize: 16,
            ),
            items: _sessionTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sessionType = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor2,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryColor,
            elevation: 8,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                    'Create New Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.darkColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Attendance Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fill details to start capturing attendance with GPS and QR Code.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Session Title',
                          hint: 'e.g., Week 5 Lecture',
                          prefixIcon: Icons.title,
                          validator: _validateTitle,
                        ),
                        const SizedBox(height: 20),

                        _buildDropdownField(),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _radiusController,
                          label: 'Allowed Radius (meters)',
                          hint: 'e.g., 50',
                          prefixIcon: Icons.radar,
                          keyboardType: TextInputType.number,
                          validator: _validateRadius,
                        ),
                        const SizedBox(height: 16),
                        
                        // GPS Status Indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isGpsReady
                                ? Colors.green.withValues(alpha: 0.1)
                                : _isGpsFailed
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isGpsReady
                                  ? Colors.green
                                  : _isGpsFailed
                                      ? Colors.red
                                      : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isGpsReady
                                    ? Icons.location_on
                                    : _isGpsFailed
                                        ? Icons.location_off
                                        : Icons.location_searching,
                                color: _isGpsReady
                                    ? Colors.green
                                    : _isGpsFailed
                                        ? Colors.red
                                        : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isGpsReady
                                      ? 'GPS Signal Ready'
                                      : _isGpsFailed
                                          ? 'GPS Unavailable (Check permissions)'
                                          : 'Fetching GPS Signal...',
                                  style: TextStyle(
                                    color: _isGpsReady
                                        ? Colors.green[800]
                                        : _isGpsFailed
                                            ? Colors.red[800]
                                            : Colors.orange[800],
                                    fontWeight: _isGpsReady ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _startSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow, size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Session',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
