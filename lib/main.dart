import 'package:flutter/material.dart';
import 'src/Header.dart';
import 'src/signup.dart';
import 'src/registration_selection.dart';
import 'src/Formclub.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

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
    Formclub(),
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
