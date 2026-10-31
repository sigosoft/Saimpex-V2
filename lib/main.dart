import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/app_dependencies.dart';
import 'core/storage/session_store.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_translations.dart';
import 'models/auth_repository.dart';
import 'views/main_shell_screen.dart';
import 'views/onboarding_screen.dart';
import 'widgets/no_internet_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.load();
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
  unawaited(_confirmStoredSession());
}

Future<void> _confirmStoredSession() async {
  if (!Get.isRegistered<SessionStore>() ||
      !Get.isRegistered<AuthRepository>()) {
    return;
  }
  final session = Get.find<SessionStore>();
  final token = session.token;
  if (token == null || token.isEmpty) return;

  final valid = await Get.find<AuthRepository>().customerCheck();
  if (!valid) await session.clear();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Saimpex V2',
      debugShowCheckedModeBanner: false,
      // UI strings come from AppTranslations; Arabic lays the app out right
      // to left through the Flutter localisation delegates.
      translations: AppTranslations(),
      locale: AppLocale.locale,
      fallbackLocale: AppLocale.fallbackLocale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
