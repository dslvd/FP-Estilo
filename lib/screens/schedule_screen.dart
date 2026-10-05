import 'package:flutter/material.dart';

import '../models/plant.dart';

class ScheduleScreen extends StatelessWidget {
  final List<Plant> plants;
  final void Function(Plant) onWater;

  const ScheduleScreen({super.key, required this.plants, required this.onWater});

  @override
  Widget build(BuildContext context) {
    final sorted = [...plants]
      ..sort((a, b) => a.nextWatering.compareTo(b.nextWatering));
    return Scaffold(
      appBar: AppBar(title: const Text('Water Schedule')),
      body: ListView(
        children: [
          for (final p in sorted)
            ListTile(
              title: Text(p.nickname),
              subtitle: Text(p.needsWaterToday
                  ? 'Water today'
                  : '${p.nextWatering.month}/${p.nextWatering.day}'),
              trailing: p.needsWaterToday
                  ? FilledButton(
                      onPressed: () => onWater(p),
                      child: const Text('Done'),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
