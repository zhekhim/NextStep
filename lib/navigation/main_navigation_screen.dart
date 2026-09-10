import 'package:flutter/material.dart';

import '../modules/career_assessment/screens/riasec_test_screen.dart';
import '../modules/career_intelligence/screens/careers_hub_screen.dart';
import '../modules/career_goals/screens/career_goal_screen.dart';
import '../modules/profile_skills/screens/profile_screen.dart';
import 'screens/home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final _screens = <Widget>[
    HomeScreen(onSelectSection: _selectSection),
    const CareersHubScreen(),
    const RiasecTestScreen(),
    const CareerGoalScreen(),
    const ProfileScreen(),
  ];

  void _selectSection(int index) {
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final navigationLabelSize = mediaQuery.size.width < 400 ? 11.0 : 12.0;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF000000),
          indicatorColor: const Color(0xFF0007CD).withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF1A26FF)
                  : const Color(0xFF888888),
              fontSize: navigationLabelSize,
              fontWeight: FontWeight.w500,
            );
          }),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectSection,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Careers',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Assessment',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
