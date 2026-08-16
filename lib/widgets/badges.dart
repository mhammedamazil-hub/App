import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme.dart';
import '../utils/dates.dart';

/// Small pill showing a due date with urgency coloring.
class DueBadge extends StatelessWidget {
  const DueBadge({
    super.key,
    required this.task,
    required this.now,
    this.compact = false,
  });

  final Task task;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final due = task.dueAt;
    if (due == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.isOverdue(now);
    final done = task.isDone;
    final dueSoon = task.isDueSoon(now);

    final Color bg;
    final Color fg;
    if (done) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    } else if (overdue) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else if (dueSoon) {
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    }

    final label = dueLabel(due, now);
    final timePart = isAllDay(due) ? '' : ' · ${fmtTime(due)}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue && !done ? Icons.error_outline : Icons.event_outlined,
            size: compact ? 12 : 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            '$label$timePart',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny priority flag.
class PriorityFlag extends StatelessWidget {
  const PriorityFlag({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    if (priority == TaskPriority.none) return const SizedBox.shrink();
    final color = priorityColor(context, priority.index);
    return Icon(Icons.flag, size: 13, color: color);
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.text,
    this.onDeleted,
    this.selected = false,
    this.onSelected,
  });

  final String text;
  final VoidCallback? onDeleted;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: selected ? Border.all(color: scheme.secondary, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$text',
            style: TextStyle(
              fontSize: 11.5,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDeleted,
              borderRadius: BorderRadius.circular(999),
              child: Icon(
                Icons.close,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    if (onSelected == null) return chip;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

/// Chip showing subtask progress (`2/5` + tiny bar).
class SubtaskChip extends StatelessWidget {
  const SubtaskChip({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = task.doneSubtasks;
    final total = task.subtasks.length;
    if (total == 0) return const SizedBox.shrink();
    final complete = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: complete
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.checklist,
            size: 13,
            color: complete
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: complete
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small chip for a repeat rule.
class RepeatChip extends StatelessWidget {
  const RepeatChip({super.key, required this.rule});

  final RepeatRule rule;

  @override
  Widget build(BuildContext context) {
    if (rule == RepeatRule.none) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            repeatLabel(rule),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small colored dot + name for a project.
class ProjectChip extends StatelessWidget {
  const ProjectChip({super.key, required this.name, required this.colorIndex});

  final String name;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: projectColor(colorIndex),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          name,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Round avatar with the project color and icon.
class ProjectAvatar extends StatelessWidget {
  const ProjectAvatar({
    super.key,
    required this.colorIndex,
    required this.iconIndex,
    this.size = 34,
  });

  final int colorIndex;
  final int iconIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = projectColor(colorIndex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(projectIcon(iconIndex), size: size * 0.55, color: color),
    );
  }
}

/// Custom round check button used on task tiles.
class CheckButton extends StatelessWidget {
  const CheckButton({
    super.key,
    required this.checked,
    required this.onTap,
    this.size = 22,
    this.color,
  });

  final bool checked;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = color ?? scheme.primary;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size + 10,
        height: size + 10,
        child: Icon(
          checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: size,
          color: checked
              ? active
              : scheme.outlineVariant.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
