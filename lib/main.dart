import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Saimpex V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF5E00),
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

