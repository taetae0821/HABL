// lib/src/app.dart

import 'package:flutter/material.dart';
import 'src/header.dart';
import 'src/registration_selection.dart';
import 'src/find_club.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _profileIndex = 4;

  int _selectedIndex = 0;
  // TODO: 로그인 기능 연결 시 final 제거하고 로그인 상태에 따라 변경
  final bool _isLoggedIn = false;

  static const List<Widget> _pages = [
    FindClub(),
    Center(child: Text('지도')),
    Center(child: Text('개설')),
    Center(child: Text('알람')),
    Center(child: Text('프로필')),
  ];

  void _onItemTapped(int index) {
    if (index == _profileIndex && !_isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const Registration()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Header(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
