import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import 'task_list_view.dart';

/// Upcoming: everything due in the next 14 days grouped by date, then
/// "Later" and "Someday".
class UpcomingView extends StatelessWidget {
  const UpcomingView({
    super.key,
    required this.state,
    required this.now,
    required this.onOpenTask,
  });

  final AppState state;
  final DateTime now;
  final void Function(Task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final upcoming = state.upcomingTasks(now);
    final later = state.laterTasks(now);

    if (upcoming.isEmpty && later.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Nothing scheduled',
        message:
            'Tasks with a due date in the next two weeks will show up here.',
      );
    }

    return TaskListView(
      state: state,
      tasks: upcoming,
      now: now,
      emptyState: const SizedBox.shrink(),
      groupByDate: true,
      dateTitle: (day, count) {
        final label = smartDate(day, now);
        final weekday = weekdayOf(day);
        final diff = dayDiff(now, day);
        if (diff == 0) return 'Today · $weekday';
        if (diff == 1) return 'Tomorrow · $weekday';
        if (diff == -1) return 'Yesterday · $weekday';
        return '$label · $weekday';
      },
      onOpenTask: onOpenTask,
      bottom: later.isEmpty
          ? null
          : _LaterSection(
              state: state,
              later: later,
              now: now,
              onOpenTask: onOpenTask,
            ),
    );
  }
}

class _LaterSection extends StatelessWidget {
  const _LaterSection({
    required this.state,
    required this.later,
    required this.now,
    required this.onOpenTask,
  });

  final AppState state;
  final List<Task> later;
  final DateTime now;
  final void Function(Task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
          child: Text(
            'Later',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final t in later)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TaskTile(
              task: t,
              now: now,
              onTap: () => onOpenTask(t),
              onToggle: () {
                if (t.isDone) {
                  state.reopenTask(t.id);
                } else {
                  state.completeTask(t.id);
                }
              },
            ),
          ),
      ],
    );
  }
}
