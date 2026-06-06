// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'Auth/main_file.dart';
import 'core/app_router.dart';
import 'core/providers/locale_provider.dart';

// Global instance of LocaleProvider (simple state management)
final localeProvider = LocaleProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the locale from saved preferences
  await localeProvider.initialize();

  runApp(const CollegeAttendanceApp());
}

class CollegeAttendanceApp extends StatefulWidget {
  const CollegeAttendanceApp({super.key});

  @override
  State<CollegeAttendanceApp> createState() => _CollegeAttendanceAppState();
}

class _CollegeAttendanceAppState extends State<CollegeAttendanceApp> {
  @override
  void initState() {
    super.initState();
    // Listen to locale changes and rebuild
    localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(
        localeProvider.locale.languageCode,
      ), // Force rebuild on locale change
      title: 'College Attendance System',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      scaffoldMessengerKey: AppRouter.messengerKey,

      // Localization setup
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // If device locale is en or ar, use it
        if (locale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        // Default to English if locale is not supported
        return const Locale('en');
      },

      theme: ThemeData(
        primaryColor: const Color(0xFF2A9D8F),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFE9C46A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1DE),
      ),
      home: const ActivationLoginPage(showLogin: true),
    );
  }
}
