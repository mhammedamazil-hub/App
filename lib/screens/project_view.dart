import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/badges.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';
import 'kanban.dart';
import 'task_list_view.dart';

enum ProjectViewMode { list, kanban }

/// A single project: header with progress, list/Kanban toggle, open tasks
/// and a collapsed completed section.
class ProjectView extends StatelessWidget {
  const ProjectView({
    super.key,
    required this.state,
    required this.project,
    required this.now,
    required this.mode,
    required this.onModeChanged,
    required this.onOpenTask,
    required this.onNewTask,
    required this.onEditProject,
    required this.onDeleteProject,
  });

  final AppState state;
  final Project project;
  final DateTime now;
  final ProjectViewMode mode;
  final void Function(ProjectViewMode mode) onModeChanged;
  final void Function(Task task) onOpenTask;
  final void Function(TaskStatus status) onNewTask;
  final VoidCallback onEditProject;
  final VoidCallback onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = state.openIn(project.id);
    final completed = state.completedIn(project.id);
    final total = open.length + completed.length;
    final rate = total == 0 ? 0.0 : completed.length / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ProjectAvatar(
                  colorIndex: project.colorIndex,
                  iconIndex: project.iconIndex,
                  size: 42,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: rate.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    projectColor(project.colorIndex)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$completed of $total done',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<ProjectViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ProjectViewMode.list,
                      label: Text('List'),
                      icon: Icon(Icons.view_list_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ProjectViewMode.kanban,
                      label: Text('Kanban'),
                      icon: Icon(Icons.view_kanban_outlined, size: 16),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) =>
                      onModeChanged(selection.first),
                  showSelectedIcon: false,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Project options',
                  icon: Icon(Icons.more_vert,
                      size: 18, color: scheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') onEditProject();
                    if (value == 'delete') onDeleteProject();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit project'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: Colors.red),
                        title: Text('Delete project',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: mode == ProjectViewMode.kanban
              ? KanbanView(
                  state: state,
                  projectId: project.id,
                  now: now,
                  onOpenTask: onOpenTask,
                  onNewTask: onNewTask,
                )
              : TaskListView(
                  state: state,
                  tasks: open,
                  now: now,
                  showProject: false,
                  onOpenTask: onOpenTask,
                  emptyState: EmptyState(
                    icon: projectIcon(project.iconIndex),
                    title: 'No open tasks',
                    message:
                        'Add your first task in “${project.name}”, or switch to the Kanban board.',
                    actionLabel: 'Add task',
                    onAction: () => onNewTask(TaskStatus.todo),
                  ),
                  bottom: completed.isEmpty
                      ? null
                      : _CompletedSection(
                          state: state,
                          completed: completed,
                          now: now,
                          onOpenTask: onOpenTask,
                        ),
                ),
        ),
      ],
    );
  }
}

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.state,
    required this.completed,
    required this.now,
    required this.onOpenTask,
  });

  final AppState state;
  final List<Task> completed;
  final DateTime now;
  final void Function(Task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
          child: Text(
            'Completed (${completed.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        for (final t in completed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TaskTile(
              task: t,
              now: now,
              dimmed: true,
              onTap: () => onOpenTask(t),
              onToggle: () => state.reopenTask(t.id),
            ),
          ),
      ],
    );
  }
}
