// ignore_for_file: avoid_print
// main_file.dart
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

// استيراد الملفات المنفصلة
import '../Home/AdminDashboard.dart';
import '../Home/CoursesListPage.dart';
import '../Home/DoctorDashboardPage.dart';
import 'activation_page.dart';
import 'colors.dart';
import 'login_page.dart';
import 'auth_storage.dart';
import 'auth_widgets.dart';
import '../core/http_interceptor.dart' as http;
import 'api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle_button.dart';
class ActivationLoginPage extends StatefulWidget {
  final bool showLogin;
  const ActivationLoginPage({super.key, this.showLogin = false});

  @override
  _ActivationLoginPageState createState() => _ActivationLoginPageState();
}

class _ActivationLoginPageState extends State<ActivationLoginPage>
    with SingleTickerProviderStateMixin {
  // State variables
  late bool _showLogin;
  String _deviceId = '';
  bool _isGettingDeviceId = false;
  bool _isCheckingLogin = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _showLogin = widget.showLogin;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // تشغيل العمليات بشكل متوازي مع ضمان عدم تعليق الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    // تشغيل الحصول على الـ ID وفحص الدخول في نفس الوقت
    await Future.wait([_checkLoginStatus(), _getDeviceId()]);
  }

  // فحص هل المستخدم مسجل دخول مسبقاً مع التحقق من صحة التوكن
  Future<void> _checkLoginStatus() async {
    try {
      final userData = await AuthStorage.getUserData();
      if (userData != null && userData['token'] != null && userData['token']!.isNotEmpty) {
        
        // التحقق من صحة التوكن عبر نداء بسيط للـ API
        final token = userData['token']!;
        final role = userData['role']!;
        
        // محاولة جلب بيانات بسيطة للتأكد من أن الجلسة ما زالت تعمل
        bool isTokenValid = false;
        try {
           final response = await http.get(
            Uri.parse('${ApiService.baseUrl}/Auth/verify-session'),
            headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            isTokenValid = true;
          } else {
            // الـ Interceptor سيحاول التحديث تلقائياً، فإذا ظل الرد 401 فالتوكن غير صالح
            isTokenValid = response.statusCode != 401;
          }
        } catch (_) {
          // في حال فشل الاتصال، نفترض أن التوكن صالح مؤقتاً لنسمح بالدخول في وضع الأوفلاين
          isTokenValid = true; 
        }

        if (isTokenValid && mounted) {
          _navigateToMainApp(
            token: userData['token']!,
            refreshToken: userData['refreshToken']!,
            role: userData['role']!,
            userName: userData['userName']!,
            email: userData['email']!,
            deviceId: userData['deviceId']!,
          );
          return;
        } else {
          // التوكن غير صالح، امسح البيانات وابقَ في صفحة الدخول
          await AuthStorage.clearUserData();
        }
      }
      
      if (mounted) {
        setState(() {
          _isCheckingLogin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLogin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // دالة للحصول على Device ID من الهاتف
  Future<void> _getDeviceId() async {
    try {
      String id = 'unknown';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        id = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? 'ios_device';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        WindowsDeviceInfo windowsInfo = await _deviceInfo.windowsInfo;
        // استخدام deviceId الفريد للويندوز مع تنظيف الأقواس
        id = windowsInfo.deviceId.replaceAll('{', '').replaceAll('}', '').trim();
      } else if (kIsWeb) {
        id = 'web_client';
      } else {
        id = 'pc_client';
      }

      if (mounted) {
        setState(() {
          _deviceId = id;
          _isGettingDeviceId = false;
        });
      }
      print('📱 Device ID Detected: $_deviceId');
    } catch (e) {
      print('Error getting device info: $e');
      if (mounted) {
        setState(() {
          _deviceId = 'error_device';
          _isGettingDeviceId = false;
        });
      }
    }
  }

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> userData) async {
    // حفظ البيانات في SharedPreferences
    await AuthStorage.saveUserData(
      token: userData['token'],
      refreshToken: userData['refreshToken'],
      role: userData['role'],
      userName: userData['userName'],
      email: userData['email'],
      deviceId: userData['deviceId'],
    );

    _navigateToMainApp(
      token: userData['token'],
      refreshToken: userData['refreshToken'],
      role: userData['role'],
      userName: userData['userName'],
      email: userData['email'],
      deviceId: userData['deviceId'],
    );
  }

  void _navigateToMainApp({
    required String token,
    required String refreshToken,
    required String role,
    required String userName,
    required String email,
    required String deviceId,
  }) {
    if (!mounted) return;
    AuthWidgets.showSuccessSnackBar(context, 'Signed in as $userName');

    Widget destination;

    if (role == 'Doctor' || role == 'TA') {
      // الدكتور والـ TA يذهبان لشاشتهم المخصصة
      destination = DoctorDashboardPage(
        userName: userName,
        email: email,
        role: role,
        token: token,
      );
    } else if (role == 'Admin') {
      destination = AdminDashboard(
        userName: userName,
        email: email,
        role: role,
        token: token,
      );
    } else {
      // Student أو أي role آخر
      destination = const CoursesListPage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Widget _buildWaveDecoration() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipPath(
        clipper: WaveClipper(),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.3),
                AppColors.secondaryColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            _buildWaveDecoration(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Top Bar with Language Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        LanguageToggleButton(
                          textColor: AppColors.primaryColor,
                          onLocaleChanged: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    // App logo and title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.collegeAttendanceSystem,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.studentAttendanceApplication,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.darkColor.withValues(alpha: 0.7),
                      ),
                    ),

                    // Activation or login form
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _showLogin
                              ? LoginPage(
                                  onSwitchToActivation: _toggleView,
                                  deviceId: _deviceId,
                                  onDeviceIdRefresh: (value) => _getDeviceId(),
                                  onLoginSuccess: _handleLoginSuccess,
                                )
                              : ActivationPage(
                                  onSwitchToLogin: _toggleView,
                                  deviceId: _deviceId,
                                  onDeviceIdRefresh: (value) => _getDeviceId(),
                                ),
                        ),
                      ),
                    ),

                    // Additional information
                    const SizedBox(height: 30),
                    Text(
                      AppLocalizations.of(context)!.forAssistanceContactIT,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkColor.withValues(alpha: 0.5),
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
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);

    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.9);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.5);
    var secondEndPoint = Offset(size.width, size.height * 0.7);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
