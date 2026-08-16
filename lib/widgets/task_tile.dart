import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../theme.dart';
import 'badges.dart';

enum TileMenuAction { edit, pin, duplicate, move, delete, reopen }

/// A single task row used in list views.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    this.project,
    this.showProject = false,
    this.onTap,
    this.onToggle,
    this.onMenu,
    this.dimmed = false,
  });

  final Task task;
  final DateTime now;
  final Project? project;
  final bool showProject;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final void Function(TileMenuAction action)? onMenu;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = task.isDone;
    final overdue = task.isOverdue(now);
    final priority = priorityColor(context, task.priority.index);

    final titleStyle =
        (done
                ? Theme.of(context).textTheme.bodyMedium
                : Theme.of(context).textTheme.bodyLarge)
            ?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : scheme.onSurface,
              fontWeight: done ? FontWeight.w400 : FontWeight.w600,
              height: 1.3,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Material(
        color: dimmed
            ? Colors.transparent
            : scheme.surfaceContainerLowest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckButton(
                  checked: done,
                  onTap: onToggle ?? () {},
                  color: done ? null : (priority ?? scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: titleStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.pinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: scheme.tertiary,
                              ),
                            ),
                          if (task.hasReminder && !done)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size: 14,
                                color: overdue
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      if (task.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.hasDue) DueBadge(task: task, now: now),
                          if (task.priority != TaskPriority.none)
                            PriorityFlag(priority: task.priority),
                          if (task.repeat != RepeatRule.none)
                            RepeatChip(rule: task.repeat),
                          if (task.subtasks.isNotEmpty) SubtaskChip(task: task),
                          for (final tag in task.tags.take(2))
                            TagChip(text: tag),
                          if (task.tags.length > 2)
                            Text(
                              '+${task.tags.length - 2}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          if (showProject && project != null)
                            ProjectChip(
                              name: project.name,
                              colorIndex: project.colorIndex,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onMenu != null) _TileMenu(task: task, onSelected: onMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileMenu extends StatelessWidget {
  const _TileMenu({required this.task, required this.onSelected});

  final Task task;
  final void Function(TileMenuAction action) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TileMenuAction>(
      tooltip: 'Task options',
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TileMenuAction.edit,
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: TileMenuAction.pin,
          child: ListTile(
            leading: Icon(
              task.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(task.pinned ? 'Unpin' : 'Pin'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (task.isDone)
          PopupMenuItem(
            value: TileMenuAction.reopen,
            child: const ListTile(
              leading: Icon(Icons.undo),
              title: Text('Reopen'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        PopupMenuItem(
          value: TileMenuAction.duplicate,
          child: const ListTile(
            leading: Icon(Icons.copy_outlined),
            title: Text('Duplicate'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: TileMenuAction.move,
          child: const ListTile(
            leading: Icon(Icons.drive_file_move_outline),
            title: Text('Move to project…'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: TileMenuAction.delete,
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}
