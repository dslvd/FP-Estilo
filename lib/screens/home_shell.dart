import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../models/species.dart';
import '../services/plant_api.dart';
import 'add_plant_screen.dart';
import 'plant_list_screen.dart';
import 'schedule_screen.dart';
import 'search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _api = PlantApi();
  final List<Plant> _plants = [
    Plant(
      id: '1',
      nickname: 'Monstera',
      species: 'Monstera deliciosa',
      waterEveryDays: 7,
      lastWatered: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Plant(
      id: '2',
      nickname: 'Snake plant',
      species: 'Dracaena trifasciata',
      waterEveryDays: 14,
      lastWatered: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  void _water(Plant plant) {
    setState(() {
      final i = _plants.indexWhere((p) => p.id == plant.id);
      _plants[i] = plant.copyWith(lastWatered: DateTime.now());
    });
  }

  void _delete(Plant plant) =>
      setState(() => _plants.removeWhere((p) => p.id == plant.id));

  void _addSpecies(Species s) {
    setState(() => _plants.add(Plant(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          nickname: s.scientificName,
          species: s.scientificName,
          waterEveryDays: 7,
          lastWatered: DateTime.now(),
        )));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${s.scientificName}')));
  }

  Future<void> _openAdd() async {
    final plant = await Navigator.of(context).push<Plant>(
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (plant != null) setState(() => _plants.add(plant));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PlantListScreen(
        plants: _plants,
        onAdd: _openAdd,
        onWater: _water,
        onDelete: _delete,
      ),
      ScheduleScreen(plants: _plants, onWater: _water),
      SearchScreen(api: _api, onAddSpecies: _addSpecies),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_florist), label: 'Plants'),
          NavigationDestination(icon: Icon(Icons.water_drop), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}
