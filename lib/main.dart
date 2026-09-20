import 'package:flutter/material.dart';
import 'src/Header.dart';

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
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    Center(child: Text('탐색')),
    Center(child: Text('지도')),
    Center(child: Text('개설')),
    Center(child: Text('알람')),
    Center(child: Text('프로필')),
  ];

  void _onItemTapped(int index) {
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
