import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/plant_list_tile.dart';
import '../widgets/watering_summary_banner.dart';

/// "My Plants" — the home tab.
///
/// Note there is no `List<Plant>` parameter: the list comes from
/// `PlantProvider` through `context.watch`, so adding a plant on another
/// screen updates this one automatically.
class PlantListScreen extends StatelessWidget {
  const PlantListScreen({super.key});

  Future<void> _openAdd(BuildContext context) async {
    await Navigator.of(context).pushNamed(Routes.addPlant);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();
    final plants = provider.plants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlantPal'),
        actions: [
          IconButton(
            tooltip: 'About PlantPal',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add plant'),
      ),
      body: plants.isEmpty
          ? EmptyState(
              icon: Icons.local_florist_outlined,
              title: 'No plants yet',
              message:
                  'Add your first plant and PlantPal will keep track of when '
                  'it needs water.',
              actionLabel: 'Add a plant',
              onAction: () => _openAdd(context),
            )
          : Column(
              children: [
                WateringSummaryBanner(
                  dueCount: provider.dueToday.length,
                  totalCount: provider.count,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: plants.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final plant = plants[i];
                      return PlantListTile(
                        plant: plant,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(Routes.plantDetail, arguments: plant),
                        trailing: IconButton(
                          tooltip: 'Water now',
                          icon: const Icon(Icons.water_drop_outlined),
                          onPressed: () => _water(context, plant),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Marks a plant watered and confirms it with a snack bar.
  Future<void> _water(BuildContext context, Plant plant) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<PlantProvider>().markWatered(plant);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${plant.nickname} watered'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => context.read<PlantProvider>().update(plant),
          ),
        ),
      );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PlantPal',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.local_florist, size: 40),
      children: const [
        Text(
          'A houseplant care tracker. Log your plants, get watering '
          'reminders, and look up care information from the GBIF and '
          'Wikipedia plant APIs.',
        ),
      ],
    );
  }
}
