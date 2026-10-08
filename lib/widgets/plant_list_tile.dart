import 'package:flutter/material.dart';

import '../models/plant.dart';

/// Reusable plant row used by the My Plants list and the Water Schedule list.
///
/// Keeping this in one place means the avatar, the two-line title/subtitle
/// layout and the optional trailing action button stay identical on both
/// screens instead of being duplicated as two similar ListTiles.
class PlantListTile extends StatelessWidget {
  final Plant plant;

  /// Tap the whole row (opens Plant Details). Omit to make the row inert.
  final VoidCallback? onTap;

  /// Optional trailing button. My Plants passes a "water now" icon button;
  /// Water Schedule passes a "Done" button on plants that are due.
  final Widget? trailing;

  const PlantListTile({
    super.key,
    required this.plant,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = plant.needsWaterToday;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: due
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_florist,
          color: due
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        plant.nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Row(
        children: [
          if (due) ...[
            Icon(Icons.priority_high, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              plant.wateringStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: due
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
                fontWeight: due ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      trailing: trailing,
    );
  }
}
