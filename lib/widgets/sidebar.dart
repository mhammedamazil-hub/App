import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../theme.dart';

/// Smart-list ids, shared between the sidebar and the shell.
enum SmartList {
  inbox,
  today,
  upcoming,
  overdue,
  completed,
  all,
  projects,
  stats,
  settings,
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.state,
    required this.now,
    required this.selectedSmart,
    required this.selectedProjectId,
    required this.onSelectSmart,
    required this.onSelectProject,
    required this.onAddProject,
    this.compact = false,
  });

  final AppState state;
  final DateTime now;
  final SmartList? selectedSmart;
  final String? selectedProjectId;
  final void Function(SmartList list) onSelectSmart;
  final void Function(Project project) onSelectProject;
  final VoidCallback onAddProject;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = _counts();
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.check, size: 19, color: scheme.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'TaskFlow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _SectionLabel(text: 'Smart lists'),
                  _NavItem(
                    icon: Icons.inbox_outlined,
                    selectedIcon: Icons.inbox,
                    label: 'Inbox',
                    count: counts['inbox'] ?? 0,
                    selected:
                        selectedSmart == SmartList.inbox &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.inbox),
                  ),
                  _NavItem(
                    icon: Icons.today_outlined,
                    selectedIcon: Icons.today,
                    label: 'Today',
                    count: counts['today'] ?? 0,
                    countColor: (counts['overdue'] ?? 0) > 0
                        ? scheme.error
                        : null,
                    selected:
                        selectedSmart == SmartList.today &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.today),
                  ),
                  _NavItem(
                    icon: Icons.event_upcoming_outlined,
                    selectedIcon: Icons.event_upcoming,
                    label: 'Upcoming',
                    count: counts['upcoming'] ?? 0,
                    selected:
                        selectedSmart == SmartList.upcoming &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.upcoming),
                  ),
                  _NavItem(
                    icon: Icons.error_outline,
                    selectedIcon: Icons.error,
                    label: 'Overdue',
                    count: counts['overdue'] ?? 0,
                    countColor: scheme.error,
                    selected:
                        selectedSmart == SmartList.overdue &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.overdue),
                  ),
                  _NavItem(
                    icon: Icons.done_all_outlined,
                    selectedIcon: Icons.done_all,
                    label: 'Completed',
                    count: counts['completed'] ?? 0,
                    selected:
                        selectedSmart == SmartList.completed &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.completed),
                  ),
                  _NavItem(
                    icon: Icons.layers_outlined,
                    selectedIcon: Icons.layers,
                    label: 'All tasks',
                    count: counts['all'] ?? 0,
                    selected:
                        selectedSmart == SmartList.all &&
                        selectedProjectId == null,
                    onTap: () => onSelectSmart(SmartList.all),
                  ),
                  const SizedBox(height: 10),
                  _SectionLabel(
                    text: 'Projects',
                    trailing: IconButton(
                      onPressed: onAddProject,
                      tooltip: 'New project',
                      icon: const Icon(Icons.add, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (state.projects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                      child: Text(
                        'No projects yet. Create one to organise tasks.',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final project in state.projects)
                    _NavItem(
                      icon: Icons.circle,
                      iconColor: projectColor(project.colorIndex),
                      label: project.name,
                      count: counts['p-${project.id}'] ?? 0,
                      selected: selectedProjectId == project.id,
                      onTap: () => onSelectProject(project),
                      onLongPress: () => onSelectProject(project),
                    ),
                  const SizedBox(height: 10),
                  _SectionLabel(text: 'Insights'),
                  _NavItem(
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights,
                    label: 'Stats',
                    selected: selectedSmart == SmartList.stats,
                    onTap: () => onSelectSmart(SmartList.stats),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Settings',
                    selected: selectedSmart == SmartList.settings,
                    onTap: () => onSelectSmart(SmartList.settings),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _counts() {
    final m = <String, int>{};
    final open = state.openTasks;
    m['inbox'] = open.where((t) => t.projectId == '').length;
    m['today'] = state.dueTodayCount(now);
    m['upcoming'] = state.upcomingTasks(now).length;
    m['overdue'] = state.overdueCount(now);
    m['completed'] = state.completedCount;
    m['all'] = state.openCount;
    for (final p in state.projects) {
      m['p-${p.id}'] = open.where((t) => t.projectId == p.id).length;
    }
    return m;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.count,
    this.countColor,
    this.iconColor,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final int? count;
  final Color? countColor;
  final Color? iconColor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.secondaryContainer : Colors.transparent;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected ? (selectedIcon ?? icon) : icon,
                  size: 18,
                  color: selected ? scheme.primary : (iconColor ?? fg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          countColor ??
                          (selected
                              ? scheme.secondary.withValues(alpha: 0.25)
                              : scheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            countColor ??
                            (selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
