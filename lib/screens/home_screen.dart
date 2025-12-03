import 'package:flutter/material.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/screens/map_screen.dart';
import 'package:rate_my_bowl/screens/list_screen.dart';
import 'package:rate_my_bowl/screens/options_screen.dart';
import 'package:rate_my_bowl/screens/debug_screen.dart';
import 'package:rate_my_bowl/widgets/bowl_logo.dart';

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
    const OptionsScreen(),
    const DebugScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const RateMyBowlLogo(
          color: Colors.white,
          size: 0.7,
          alignment: MainAxisAlignment.start,
        ),
  // no actions here; logout moved into Options screen
  actions: [],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.lightBlueAccent,
        selectedItemColor: colors.onPrimary,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'List'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Options',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: 'Debug'),
        ],
      ),
    );
  }
}
