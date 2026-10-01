import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Header({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: '탐색'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
        BottomNavigationBarItem(icon: Icon(Icons.create), label: '개설'),
        BottomNavigationBarItem(icon: Icon(Icons.alarm), label: '알람'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
      ],
    );
  }
}
