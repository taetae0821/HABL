import 'package:flutter/material.dart';
import 'm_signup.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habl',
      theme: buildAppTheme(),
      home: const Signup(),
    );
  }
}
