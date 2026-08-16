import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

/// Today: reminders that fired, overdue, due today, and what was completed
/// today.
class TodayView extends StatelessWidget {
  const TodayView({
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
    final overdue = state.overdueTasks(now);
    final dueToday = state.tasksDueToday(now);
    final completed = state.completedToday(now);
    final reminders = state.pendingReminders(now);

    if (overdue.isEmpty && dueToday.isEmpty && reminders.isEmpty) {
      return EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'Nothing due today',
        message: overdue.isEmpty
            ? 'Enjoy the calm — or plan ahead with a new task.'
            : 'All caught up!',
        actionLabel: 'Add a task',
        onAction: () => onOpenTask(Task(
          id: '',
          title: '',
          createdAt: DateTime.now(),
        )),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        if (reminders.isNotEmpty) ...[
          const _Header('Reminders', icon: Icons.alarm),
          for (final t in reminders.take(3))
            _tile(context, t, highlight: true),
        ],
        if (overdue.isNotEmpty) ...[
          const _Header('Overdue', icon: Icons.error_outline),
          for (final t in overdue) _tile(context, t),
        ],
        if (dueToday.isNotEmpty) ...[
          const _Header('Due today', icon: Icons.today_outlined),
          for (final t in dueToday) _tile(context, t),
        ],
        if (overdue.isEmpty && dueToday.isEmpty) ...[
          const SizedBox(height: 40),
          EmptyState(
            icon: Icons.wb_sunny_outlined,
            title: 'All done for today',
            message: 'Your overdue list is clear and nothing is due today.',
            actionLabel: 'Add a task',
            onAction: () => onOpenTask(Task(
              id: '',
              title: '',
              createdAt: DateTime.now(),
            )),
          ),
        ],
        if (completed.isNotEmpty) ...[
          const _Header(
            'Completed today',
            icon: Icons.done_all_outlined,
            trailing: true,
          ),
          for (final t in completed) _tile(context, t, dimmed: true),
        ],
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    Task t, {
    bool highlight = false,
    bool dimmed = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey('today-${t.id}'),
        direction: DismissDirection.horizontal,
        background: _bg(context, Alignment.centerLeft,
            Icons.check, 'Complete', scheme.primary),
        secondaryBackground: _bg(context, Alignment.centerRight,
            Icons.delete_outline, 'Delete', scheme.error),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            final title = state.deleteTask(t.id);
            if (title != null) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content: Text('Deleted “$title”'),
                duration: const Duration(seconds: 6),
                action: state.canUndo
                    ? SnackBarAction(
                        label: 'Undo',
                        onPressed: () => state.undo(),
                      )
                    : null,
              ));
            }
          } else if (t.isDone) {
            state.reopenTask(t.id);
          } else {
            final result = state.completeTask(t.id);
            if (result != null && result.next != null) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(SnackBar(
                content: Text(
                    'Completed — next: ${dueLabel(result.next!.dueAt!, now)}'),
                duration: const Duration(seconds: 3),
              ));
            }
          }
        },
        child: Material(
          color: highlight
              ? scheme.tertiaryContainer.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
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
            dimmed: dimmed,
          ),
        ),
      ),
    );
  }

  Widget _bg(BuildContext context, Alignment alignment, IconData icon,
      String label, Color color) {
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, {this.icon, this.trailing = false});

  final String title;
  final IconData? icon;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: trailing
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
