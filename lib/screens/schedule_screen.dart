import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/plant_list_tile.dart';
import '../widgets/watering_summary_banner.dart';

/// "Water Schedule" tab — the plant list re-ordered by next watering date.
///
/// Reads the same [PlantProvider] as My Plants but uses the provider's
/// `byNextWatering` getter, which is exactly the kind of derived state that
/// belongs in the provider rather than in the widget.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();
    final plants = provider.byNextWatering;

    return Scaffold(
      appBar: AppBar(title: const Text('Water Schedule')),
      body: plants.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing scheduled',
              message:
                  'Once you add plants, they will appear here ordered by when '
                  'they next need water.',
            )
          : Column(
              children: [
                WateringSummaryBanner(
                  dueCount: provider.dueToday.length,
                  totalCount: provider.count,
                ),
                Expanded(
                  child: ListView.separated(
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
                        trailing: plant.needsWaterToday
                            ? FilledButton.tonal(
                                onPressed: () => context
                                    .read<PlantProvider>()
                                    .markWatered(plant),
                                child: const Text('Done'),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
