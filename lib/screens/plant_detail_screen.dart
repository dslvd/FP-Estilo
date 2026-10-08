import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_provider.dart';
import '../routes.dart';

/// "Plant Details" — everything about one plant, plus the actions on it.
///
/// The plant arrives as a route argument, but the *live* copy is re-read from
/// [PlantProvider] on every build. That way marking it watered or editing it
/// updates this screen immediately instead of showing stale values.
class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Plant) {
      return const Scaffold(
        body: Center(child: Text('No plant was selected.')),
      );
    }

    final provider = context.watch<PlantProvider>();
    // Fall back to the argument if the plant was deleted from another screen.
    final plant = provider.plants.firstWhere(
      (p) => p.id == arg.id,
      orElse: () => arg,
    );

    final theme = Theme.of(context);
    final due = plant.needsWaterToday;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.nickname),
        actions: [
          IconButton(
            tooltip: 'Edit plant',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(Routes.addPlant, arguments: plant),
          ),
          IconButton(
            tooltip: 'Delete plant',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, plant),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(plant: plant, due: due),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.science_outlined,
                  label: 'Species',
                  value: plant.species.isEmpty ? 'Not recorded' : plant.species,
                ),
                const Divider(height: 1, indent: 56),
                _DetailRow(
                  icon: Icons.repeat,
                  label: 'Watering interval',
                  value:
                      'Every ${plant.waterEveryDays} '
                      'day${plant.waterEveryDays == 1 ? '' : 's'}',
                ),
                const Divider(height: 1, indent: 56),
                _DetailRow(
                  icon: Icons.history,
                  label: 'Last watered',
                  value: _formatDate(plant.lastWatered),
                ),
                const Divider(height: 1, indent: 56),
                _DetailRow(
                  icon: Icons.event,
                  label: 'Next watering',
                  value: _formatDate(plant.nextWatering),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _water(context, plant),
            icon: const Icon(Icons.water_drop),
            label: const Text('Mark as watered'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(Routes.addPlant, arguments: plant),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit details'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _confirmDelete(context, plant),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete plant'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _water(BuildContext context, Plant plant) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<PlantProvider>().markWatered(plant);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${plant.nickname} watered')));
  }

  /// Deletes only after an explicit confirmation, then returns to the list.
  Future<void> _confirmDelete(BuildContext context, Plant plant) async {
    final provider = context.read<PlantProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this plant?'),
        content: Text(
          '"${plant.nickname}" and its watering history will be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await provider.remove(plant);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${plant.nickname} deleted')));
    navigator.pop();
  }
}

/// The prominent status block at the top of the detail screen.
class _StatusCard extends StatelessWidget {
  final Plant plant;
  final bool due;

  const _StatusCard({required this.plant, required this.due});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = due
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final fg = due
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            due ? Icons.priority_high : Icons.check_circle_outline,
            color: fg,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            plant.wateringStatus,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            due
                ? 'Give it a drink and tap "Mark as watered".'
                : 'Next due ${PlantDetailScreen._formatDate(plant.nextWatering)}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// One icon + label + value row inside the details card.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.outline),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
