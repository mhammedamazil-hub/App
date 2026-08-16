import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../theme.dart';
import '../widgets/badges.dart';
import '../widgets/empty_state.dart';

/// Grid of project cards (used as the Projects destination on mobile).
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    super.key,
    required this.state,
    required this.onOpenProject,
    required this.onAddProject,
    required this.onEditProject,
    required this.onDeleteProject,
  });

  final AppState state;
  final void Function(Project project) onOpenProject;
  final VoidCallback onAddProject;
  final void Function(Project project) onEditProject;
  final void Function(Project project) onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final progress = state.projectProgress();
    if (progress.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No projects yet',
        message:
            'Projects keep related tasks together — Work, Personal, '
            'Health, or anything else.',
        actionLabel: 'Create project',
        onAction: onAddProject,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
      itemCount: progress.length,
      itemBuilder: (context, index) {
        final p = progress[index];
        return _ProjectCard(
          progress: p,
          onTap: () => onOpenProject(p.project),
          onEdit: () => onEditProject(p.project),
          onDelete: () => onDeleteProject(p.project),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.progress,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectProgress progress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = projectColor(progress.project.colorIndex);
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProjectAvatar(
                    colorIndex: progress.project.colorIndex,
                    iconIndex: progress.project.iconIndex,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progress.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: 'Project options',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.rate.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.done} of ${progress.total} done · ${progress.open} open',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
