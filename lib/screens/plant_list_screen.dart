import 'package:flutter/material.dart';

import '../models/plant.dart';
import 'plant_detail_screen.dart';

class PlantListScreen extends StatelessWidget {
  final List<Plant> plants;
  final VoidCallback onAdd;
  final void Function(Plant) onWater;
  final void Function(Plant) onDelete;

  const PlantListScreen({
    super.key,
    required this.plants,
    required this.onAdd,
    required this.onWater,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PlantPal')),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: plants.isEmpty
          ? const Center(child: Text('No plants yet. Tap + to add one.'))
          : ListView(
              children: [
                for (final p in plants)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.local_florist)),
                    title: Text(p.nickname),
                    subtitle: Text(p.needsWaterToday
                        ? 'Water today'
                        : 'Next: ${p.nextWatering.month}/${p.nextWatering.day}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.water_drop_outlined),
                      onPressed: () => onWater(p),
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlantDetailScreen(
                        plant: p,
                        onWater: onWater,
                        onDelete: onDelete,
                      ),
                    )),
                  ),
              ],
            ),
    );
  }
}
