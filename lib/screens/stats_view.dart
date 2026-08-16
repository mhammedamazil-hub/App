import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_widgets.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key, required this.state, required this.now});

  final AppState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = state.completionRate;
    final streak = state.currentStreak(now);
    final progress = state.projectProgress();
    final openByPriority = _priorityCounts(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      children: [
        Text(
          'Your activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final cardW = (constraints.maxWidth - (cols - 1) * 12.0) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardW,
                  child: StatCard(
                    label: 'Open tasks',
                    value: '${state.openCount}',
                    icon: Icons.radio_button_unchecked,
                    color: scheme.primary,
                    subtitle: state.overdueCount(now) > 0
                        ? '${state.overdueCount(now)} overdue'
                        : null,
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: StatCard(
                    label: 'Completed',
                    value: '${state.completedCount}',
                    icon: Icons.done_all,
                    color: const Color(0xFF0CA678),
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: StatCard(
                    label: 'Completion rate',
                    value: '${(rate * 100).round()}%',
                    icon: Icons.trending_up,
                    color: const Color(0xFF7048E8),
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: StatCard(
                    label: 'Day streak',
                    value: '$streak',
                    icon: Icons.local_fire_department_outlined,
                    color: const Color(0xFFF76707),
                    subtitle: streak > 0 ? 'days in a row' : null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completed in the last 7 days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              WeekBarChart(
                values: state.completedLast7Days(now),
                now: now,
                color: scheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (openByPriority.isNotEmpty)
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open tasks by priority',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                for (final entry in openByPriority)
                  ProgressRow(
                    leading: Row(
                      children: [
                        Icon(
                          entry.priority == TaskPriority.none
                              ? Icons.remove_circle_outline
                              : Icons.flag,
                          size: 16,
                          color:
                              priorityColor(context, entry.priority.index) ??
                              scheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(_priorityName(entry.priority)),
                      ],
                    ),
                    rate: state.openCount == 0
                        ? 0
                        : entry.count / state.openCount,
                    trailing: '${entry.count}',
                    color:
                        priorityColor(context, entry.priority.index) ??
                        scheme.outline,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              if (progress.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Create projects to see their progress here.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              for (final p in progress)
                ProgressRow(
                  leading: Row(
                    children: [
                      ProjectAvatar(
                        colorIndex: p.project.colorIndex,
                        iconIndex: p.project.iconIndex,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  rate: p.rate,
                  trailing: '${p.done}/${p.total}',
                  color: projectColor(p.project.colorIndex),
                ),
            ],
          ),
        ),
        if (state.totalTasks == 0) ...[
          const SizedBox(height: 40),
          EmptyState(
            icon: Icons.insights_outlined,
            title: 'No data yet',
            message: 'Complete some tasks and your stats will light up here.',
          ),
        ],
      ],
    );
  }

  List<MapEntry<TaskPriority, int>> _priorityCounts(AppState state) {
    final counts = <TaskPriority, int>{};
    for (final t in state.openTasks) {
      counts[t.priority] = (counts[t.priority] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.key.index.compareTo(a.key.index));
    return entries;
  }

  String _priorityName(TaskPriority p) {
    switch (p) {
      case TaskPriority.none:
        return 'No priority';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}
