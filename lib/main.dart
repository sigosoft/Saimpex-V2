import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/app_dependencies.dart';
import 'core/storage/session_store.dart';
import 'views/main_shell_screen.dart';
import 'views/onboarding_screen.dart';
import 'widgets/no_internet_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.init();
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
        return NoInternetGuard(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _startScreen(),
    );
  }
}

Widget _startScreen() {
  if (!Get.isRegistered<SessionStore>()) {
    return const OnboardingScreen();
  }
  final token = Get.find<SessionStore>().token;
  if (token != null && token.isNotEmpty) {
    return const MainShellScreen();
  }
  return const OnboardingScreen();
}
