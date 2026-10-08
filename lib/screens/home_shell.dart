import 'package:flutter/material.dart';

import 'plant_list_screen.dart';
import 'schedule_screen.dart';
import 'search_screen.dart';

/// The app shell that hosts the three tabs behind a bottom navigation bar.
///
/// [IndexedStack] keeps all three screens alive at once, so scroll position
/// and the search field's text survive when the user switches tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.local_florist_outlined),
      selectedIcon: Icon(Icons.local_florist),
      label: 'My Plants',
    ),
    NavigationDestination(
      icon: Icon(Icons.water_drop_outlined),
      selectedIcon: Icon(Icons.water_drop),
      label: 'Schedule',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [PlantListScreen(), ScheduleScreen(), SearchScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
