import 'package:dash_no_internet_screen/dash_no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Saimpex V2',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF5E00),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      builder: (context, child) {
        return DashNoInterNetScreen(
          backgroundColor: const Color(0xFFFAF6F0),
          padding: const EdgeInsets.all(32),
          spacing: 24,
          titleText: 'Oops!',
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C2520),
          ),
          subtitleText:
              'No Internet Connection Found. Check your connection and try again.',
          subtitleTextStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7A6A60),
            height: 1.4,
          ),
          image: Icon(
            Icons.wifi_off_rounded,
            size: 120,
            color: const Color(0xFFFF5E00).withValues(alpha: 0.85),
          ),
          buttonText: 'Try Again',
          buttonColor: const Color(0xFFFF5E00),
          buttonTextColor: Colors.white,
          buttonWidth: 220,
          buttonHeight: 52,
          buttonBorderShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          buttonTextStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const OnboardingScreen(),
    );
  }
}
