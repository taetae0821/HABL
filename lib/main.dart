import 'package:flutter/material.dart';
import 'src/signup.dart';

import 'src/app.dart';

void main(){
  runApp(const MyApp());
<<<<<<< HEAD
=======
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false, // DEBUG 띠 제거
  theme: ThemeData(
    colorSchemeSeed: const Color(0xFF4F46E5), // 메인 색 (원하는 색으로 변경)
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIconColor: Colors.grey.shade500,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    ),
  ),
  home: const Signup(),
);
  }
>>>>>>> bb04ffb (feat: add sign-up screen)
}