import 'package:flutter/material.dart';

/// Reusable summary banner shown at the top of My Plants.
///
/// Turns the shared provider state into one sentence the user can act on
/// ("2 plants need water today") and gives them a shortcut to the schedule.
/// Reusing it on the schedule screen keeps the wording consistent.
class WateringSummaryBanner extends StatelessWidget {
  final int dueCount;
  final int totalCount;
  final VoidCallback? onViewSchedule;

  const WateringSummaryBanner({
    super.key,
    required this.dueCount,
    required this.totalCount,
    this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDone = dueCount == 0;
    final bg = allDone
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final fg = allDone
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;

    final String headline;
    if (totalCount == 0) {
      headline = 'No plants yet';
    } else if (allDone) {
      headline = 'All $totalCount plants are watered';
    } else {
      headline = '$dueCount of $totalCount need water today';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.check_circle_outline : Icons.water_drop,
            color: fg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!allDone && onViewSchedule != null)
            TextButton(
              onPressed: onViewSchedule,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Schedule'),
            ),
        ],
      ),
    );
  }
}
