import 'package:flutter/material.dart';
import 'home_page.dart';
import 'calender_page.dart';
import 'camera_page.dart';
import 'setting_page/setting_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

final Color themeColor = const Color(0xFF0F624C);

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CalendarPage(),
    const HomePage(),
    const SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraPage()),
            );
          },

          backgroundColor: const Color(0xFF0F624C),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        padding: EdgeInsets.zero,
        height: 75,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.calendar_month_outlined,
                color: _currentIndex == 0 ? themeColor : Colors.grey,
              ),
              onPressed: () => setState(() => _currentIndex = 0),
            ),

            IconButton(
              icon: Icon(
                Icons.home_outlined,
                color: _currentIndex == 1 ? themeColor : Colors.grey,
              ),
              onPressed: () {
                setState(() => _currentIndex = 1);
              },
            ),

            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: _currentIndex == 2 ? themeColor : Colors.grey,
              ),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}
