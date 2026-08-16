import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../widgets/badges.dart';

/// A 3-column Kanban board (To Do / In Progress / Done) with drag & drop
/// between columns and within a column.
class KanbanView extends StatelessWidget {
  const KanbanView({
    super.key,
    required this.state,
    required this.projectId,
    required this.now,
    required this.onOpenTask,
    required this.onNewTask,
  });

  final AppState state;
  final String projectId;
  final DateTime now;
  final void Function(Task) onOpenTask;
  final void Function(TaskStatus status) onNewTask;

  @override
  Widget build(BuildContext context) {
    final byStatus = <TaskStatus, List<Task>>{
      for (final s in TaskStatus.values)
        s: state.tasks
            .where((t) => t.projectId == projectId && t.status == s)
            .toList(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth >= 860
            ? (constraints.maxWidth - 48) / 3
            : 280.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in TaskStatus.values) ...[
                SizedBox(
                  width: columnWidth,
                  child: _KanbanColumn(
                    status: status,
                    tasks: byStatus[status]!,
                    state: state,
                    now: now,
                    onOpenTask: onOpenTask,
                    onNewTask: onNewTask,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.state,
    required this.now,
    required this.onOpenTask,
    required this.onNewTask,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final AppState state;
  final DateTime now;
  final void Function(Task) onOpenTask;
  final void Function(TaskStatus status) onNewTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add task',
                  icon: const Icon(Icons.add, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onNewTask(status),
                ),
              ],
            ),
          ),
          DragTarget<Task>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final task = details.data;
              if (task.status != status) {
                state.setStatus(task.id, status);
              }
              state.moveTaskBefore(task.id, null);
            },
            builder: (context, candidate, rejected) {
              final highlight = candidate.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: highlight
                      ? scheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: highlight
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  children: [
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 30,
                              color: scheme.outlineVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Drop tasks here',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final task in tasks)
                      _KanbanCard(
                        key: ValueKey('kanban-${task.id}'),
                        task: task,
                        state: state,
                        now: now,
                        onOpenTask: onOpenTask,
                        onDropBefore: (dragged, before) {
                          if (dragged.status != status) {
                            state.setStatus(dragged.id, status);
                          }
                          state.moveTaskBefore(dragged.id, before.id);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _statusName {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.doing:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case TaskStatus.todo:
        return Theme.of(context).colorScheme.outline;
      case TaskStatus.doing:
        return const Color(0xFFF59F00);
      case TaskStatus.done:
        return const Color(0xFF0CA678);
    }
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    super.key,
    required this.task,
    required this.state,
    required this.now,
    required this.onOpenTask,
    required this.onDropBefore,
  });

  final Task task;
  final AppState state;
  final DateTime now;
  final void Function(Task) onOpenTask;
  final void Function(Task dragged, Task before) onDropBefore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onOpenTask(task),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                CheckButton(
                  checked: task.isDone,
                  size: 18,
                  color: const Color(0xFF0CA678),
                  onTap: () {
                    state.setStatus(
                      task.id,
                      task.status == TaskStatus.done
                          ? TaskStatus.todo
                          : TaskStatus.done,
                    );
                  },
                ),
              ],
            ),
            if (task.hasDue || task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (task.hasDue)
                    DueBadge(task: task, now: now, compact: true),
                  if (task.subtasks.isNotEmpty) SubtaskChip(task: task),
                  if (task.priority.index > 0)
                    PriorityFlag(priority: task.priority),
                  if (task.pinned)
                    Icon(Icons.push_pin, size: 13, color: scheme.tertiary),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DragTarget<Task>(
        onWillAcceptWithDetails: (details) => details.data.id != task.id,
        onAcceptWithDetails: (details) => onDropBefore(details.data, task),
        builder: (context, candidate, rejected) {
          return Column(
            children: [
              if (candidate.isNotEmpty)
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              Draggable<Task>(
                data: task,
                affinity: Axis.vertical,
                dragAnchorStrategy: childDragAnchorStrategy,
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Material(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: card),
                child: card,
              ),
            ],
          );
        },
      ),
    );
  }
}
