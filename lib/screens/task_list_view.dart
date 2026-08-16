import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/task_tile.dart';

/// Generic task list with optional date grouping, swipe actions and a
/// leading summary widget.
class TaskListView extends StatelessWidget {
  const TaskListView({
    super.key,
    required this.state,
    required this.tasks,
    required this.now,
    required this.emptyState,
    this.leading,
    this.showProject = false,
    this.groupByDate = false,
    this.dateTitle,
    this.swipeReopen = false,
    this.onOpenTask,
    this.bottom,
  });

  final AppState state;
  final List<Task> tasks;
  final DateTime now;
  final Widget emptyState;
  final Widget? leading;
  final bool showProject;
  final bool groupByDate;
  final String Function(DateTime day, int count)? dateTitle;
  final bool swipeReopen;
  final void Function(Task task)? onOpenTask;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty && leading == null && bottom == null) {
      return emptyState;
    }

    final rows = <Widget>[];
    if (leading != null) rows.add(leading!);

    if (groupByDate) {
      DateTime? currentDay;
      var bucket = <Task>[];
      void flush() {
        if (bucket.isEmpty) return;
        final day = currentDay!;
        final title =
            dateTitle?.call(day, bucket.length) ?? smartDate(day, now);
        rows.add(
          _SectionHeader(
            title: title,
            color: isSameDay(day, now)
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        );
        rows.addAll(bucket.map((t) => _tile(context, t)));
        bucket = [];
      }

      for (final t in tasks) {
        final key = t.dueAt ?? t.completedAt ?? t.createdAt;
        final day = startOfDay(key);
        if (currentDay == null || !isSameDay(currentDay!, day)) {
          flush();
          currentDay = day;
        }
        bucket.add(t);
      }
      flush();
    } else {
      rows.addAll(tasks.map((t) => _tile(context, t)));
    }

    if (bottom != null) rows.add(bottom!);

    if (rows.isEmpty) return emptyState;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: rows,
    );
  }

  Widget _tile(BuildContext context, Task t) {
    final project = t.projectId.isEmpty ? null : state.projectById(t.projectId);
    return Dismissible(
      key: ValueKey('task-${t.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(
        context,
        alignment: Alignment.centerLeft,
        icon: swipeReopen ? Icons.undo : Icons.check,
        label: swipeReopen ? 'Reopen' : 'Complete',
        color: Theme.of(context).colorScheme.primary,
      ),
      secondaryBackground: _swipeBackground(
        context,
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        label: 'Delete',
        color: Theme.of(context).colorScheme.error,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          final title = state.deleteTask(t.id);
          if (title != null) {
            _snack(context, 'Deleted “$title”', undoable: true);
          }
        } else if (swipeReopen) {
          state.reopenTask(t.id);
          _snack(context, 'Reopened “${t.title}”');
        } else {
          final result = state.completeTask(t.id);
          if (result != null) {
            if (result.next != null) {
              _snack(
                context,
                'Completed — next occurrence scheduled for ${dueLabel(result.next!.dueAt!, now)}',
              );
            } else {
              _snack(context, 'Completed “${t.title}”', undoable: false);
            }
          }
        }
      },
      child: TaskTile(
        task: t,
        now: now,
        project: project,
        showProject: showProject,
        onTap: () => onOpenTask?.call(t),
        onToggle: () {
          if (t.isDone) {
            state.reopenTask(t.id);
          } else {
            final result = state.completeTask(t.id);
            if (result != null && result.next != null) {
              _snack(
                context,
                'Completed — next occurrence scheduled for ${dueLabel(result.next!.dueAt!, now)}',
              );
            }
          }
        },
        onMenu: (action) => _handleMenu(context, t, action),
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, Task t, TileMenuAction action) {
    switch (action) {
      case TileMenuAction.edit:
        onOpenTask?.call(t);
      case TileMenuAction.pin:
        state.togglePin(t.id);
      case TileMenuAction.duplicate:
        state.duplicateTask(t.id);
        _snack(context, 'Duplicated “${t.title}”');
      case TileMenuAction.move:
        showMoveToProjectDialog(context, state, t);
      case TileMenuAction.delete:
        final title = state.deleteTask(t.id);
        if (title != null) {
          _snack(context, 'Deleted “$title”', undoable: true);
        }
      case TileMenuAction.reopen:
        state.reopenTask(t.id);
    }
  }

  void _snack(BuildContext context, String message, {bool undoable = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        duration: Duration(seconds: undoable ? 6 : 3),
        action: undoable && state.canUndo
            ? SnackBarAction(label: 'Undo', onPressed: () => state.undo())
            : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.color, this.trailing});

  final String title;
  final Color? color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: color ?? scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Shows the project-picker dialog and moves a task.
Future<void> showMoveToProjectDialog(
  BuildContext context,
  AppState state,
  Task task,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final target = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Move to project'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Row(
            children: [
              Icon(Icons.inbox_outlined, size: 20),
              SizedBox(width: 12),
              Text('Inbox'),
            ],
          ),
        ),
        for (final p in state.projects)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(p.id),
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: projectColor(p.colorIndex)),
                const SizedBox(width: 12),
                Text(p.name),
              ],
            ),
          ),
      ],
    ),
  );
  if (target == null || target == task.projectId) return;
  state.moveTask(task.id, target);
  final name = target.isEmpty
      ? 'Inbox'
      : (state.projectById(target)?.name ?? 'project');
  messenger.showSnackBar(
    SnackBar(
      content: Text('Moved “${task.title}” to $name'),
      duration: const Duration(seconds: 3),
    ),
  );
}
