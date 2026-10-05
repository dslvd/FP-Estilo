import 'package:flutter/material.dart';

import '../models/plant.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;
  final void Function(Plant) onWater;
  final void Function(Plant) onDelete;

  const PlantDetailScreen({
    super.key,
    required this.plant,
    required this.onWater,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plant.nickname)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plant.species, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Water every ${plant.waterEveryDays} days'),
            Text('Last watered: ${plant.lastWatered.month}/${plant.lastWatered.day}'),
            Text('Next watering: ${plant.nextWatering.month}/${plant.nextWatering.day}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                onWater(plant);
                Navigator.of(context).pop();
              },
              child: const Text('Mark as watered'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                onDelete(plant);
                Navigator.of(context).pop();
              },
              child: const Text('Delete plant'),
            ),
          ],
        ),
      ),
    );
  }
}
