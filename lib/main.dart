import 'package:flutter/material.dart';
import 'src/header.dart';
import 'src/registration_selection.dart';
import 'src/form_club.dart';
import 'src/find_club.dart';
import 'src/auth.dart';
import 'src/login.dart';
import 'src/social_auth.dart';
import 'src/theme.dart';
import 'src/profile.dart';
import 'src/alarm.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initSocialAuth();
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    // 로그인 안 되어 있으면 로그인 화면, 되어 있으면 메인 화면
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habl',
      theme: buildAppTheme(),
      home: ValueListenableBuilder<bool>(
        valueListenable: isLoggedIn,
        builder: (_, loggedIn, _) =>
            loggedIn ? const HomePage() : const Login(),
      ),
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
  bool get _isLoggedIn => isLoggedIn.value;

  static const List<Widget> _pages = [
    FindClub(),
    Center(child: Text('지도')),
    Formclub(),
    Alarm(),
    Profile(),
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
