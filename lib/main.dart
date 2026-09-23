import 'package:flutter/material.dart';
import 'src/Header.dart';
import 'src/signup.dart';

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
  bool _isLoggedIn = false;

  static const List<Widget> _pages = [
    Center(child: Text('탐색')),
    Center(child: Text('지도')),
    Center(child: Text('개설')),
    Center(child: Text('알람')),
    Center(child: Text('프로필')),
  ];

  void _onItemTapped(int index) {
    if (index == _profileIndex && !_isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const Signup()),
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
