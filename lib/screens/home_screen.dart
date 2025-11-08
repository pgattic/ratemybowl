import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/screens/map_screen.dart';
import 'package:rate_my_bowl/screens/list_screen.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';
import 'package:rate_my_bowl/screens/settings_screen.dart';
import 'package:rate_my_bowl/screens/adding_bathroom_screen.dart';
import 'package:rate_my_bowl/screens/debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MapScreen(),
    const ListScreen(),
    const SettingsScreen(),
    const DebugScreen(),
    //const ReviewScreen(hintText: "Write your review here..."),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              style: GoogleFonts.quicksand(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              "rate my "
            ),
            SvgPicture.asset(
              width: 12.0,
              height: 24.0,
              "assets/toilet.svg"
            ),
            Text(
              style: GoogleFonts.quicksand(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              "owl"
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthService>().logout();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.lightBlueAccent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: 'Debug',
          ),
        ],
      ),
    );
  }
}

