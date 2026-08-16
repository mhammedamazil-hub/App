import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/ids.dart';
import '../widgets/badges.dart';

/// Opens the task editor as a bottom sheet.
Future<void> showTaskEditor(
  BuildContext context,
  AppState state, {
  Task? task,
  String? presetProjectId,
  TaskStatus? presetStatus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => TaskEditorSheet(
      state: state,
      task: task,
      presetProjectId: presetProjectId,
      presetStatus: presetStatus,
    ),
  );
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    required this.state,
    this.task,
    this.presetProjectId,
    this.presetStatus,
  });

  final AppState state;
  final Task? task;
  final String? presetProjectId;
  final TaskStatus? presetStatus;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagCtrl;
  late final TextEditingController _subtaskCtrl;

  late String _projectId;
  late TaskStatus _status;
  late TaskPriority _priority;
  late RepeatRule _repeat;
  late DateTime? _dueAt;
  late DateTime? _reminderAt;
  late List<String> _tags;
  late List<Subtask> _subtasks;
  late bool _pinned;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _tagCtrl = TextEditingController();
    _subtaskCtrl = TextEditingController();
    _projectId = t?.projectId ?? widget.presetProjectId ?? '';
    _status = t?.status ?? widget.presetStatus ?? TaskStatus.todo;
    _priority = t?.priority ?? TaskPriority.none;
    _repeat = t?.repeat ?? RepeatRule.none;
    _dueAt = t?.dueAt;
    _reminderAt = t?.reminderAt;
    _tags = List.of(t?.tags ?? const []);
    _subtasks = (t?.subtasks ?? const []).map((s) => s.copy()).toList();
    _pinned = t?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _tagCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit task' : 'New task',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleCtrl,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Notes…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Project'),
                _projectPicker(scheme),
                const SizedBox(height: 16),
                _label('Status'),
                const SizedBox(height: 8),
                SegmentedButton<TaskStatus>(
                  segments: const [
                    ButtonSegment(
                        value: TaskStatus.todo, label: Text('To Do')),
                    ButtonSegment(
                        value: TaskStatus.doing, label: Text('Doing')),
                    ButtonSegment(
                        value: TaskStatus.done, label: Text('Done')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) =>
                      setState(() => _status = s.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                _label('Priority'),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: [
                    for (final p in TaskPriority.values)
                      ButtonSegment(
                        value: p,
                        label: Text(_priorityName(p)),
                        icon: p == TaskPriority.none
                            ? const Icon(Icons.remove, size: 14)
                            : Icon(
                                Icons.flag,
                                size: 14,
                                color: priorityColor(context, p.index),
                              ),
                      ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) =>
                      setState(() => _priority = s.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                _label('Due date'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _pickerButton(
                        icon: Icons.calendar_today_outlined,
                        text: _dueAt == null
                            ? 'Set date'
                            : (isAllDay(_dueAt!)
                                ? fmtDate(_dueAt!)
                                : '${fmtDate(_dueAt!)} · ${fmtTime(_dueAt!)}'),
                        onTap: _pickDueDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pickerButton(
                        icon: Icons.schedule_outlined,
                        text: _dueAt == null
                            ? 'Set time'
                            : (isAllDay(_dueAt!) ? 'All day' : fmtTime(_dueAt!)),
                        onTap: _pickDueTime,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: _dueAt == null
                          ? null
                          : () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Reminder'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _reminderChip('None', _reminderAt == null, () {
                      setState(() => _reminderAt = null);
                    }),
                    _reminderChip('+30 min', _isReminderOffset(30), () {
                      setState(() => _reminderAt = _reminderBase()
                          .add(const Duration(minutes: 30)));
                    }),
                    _reminderChip('+1 hour', _isReminderOffset(60), () {
                      setState(() => _reminderAt = _reminderBase()
                          .add(const Duration(hours: 1)));
                    }),
                    _reminderChip('+3 hours', _isReminderOffset(180), () {
                      setState(() => _reminderAt = _reminderBase()
                          .add(const Duration(hours: 3)));
                    }),
                    _reminderChip('Tomorrow 9 AM', _isTomorrowNine(), () {
                      final base = startOfDay(DateTime.now())
                          .add(const Duration(days: 1, hours: 9));
                      setState(() => _reminderAt = base);
                    }),
                    _reminderChip('Custom…', _reminderAt != null &&
                        !_isReminderOffset(30) &&
                        !_isReminderOffset(60) &&
                        !_isReminderOffset(180) &&
                        !_isTomorrowNine(), _pickCustomReminder),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Repeat'),
                const SizedBox(height: 8),
                _dropdown<RepeatRule>(
                  value: _repeat,
                  items: RepeatRule.values,
                  labelOf: repeatLabel,
                  onChanged: (v) => setState(() => _repeat = v ?? RepeatRule.none),
                ),
                if (_repeat != RepeatRule.none && _dueAt == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Set a due date above so the next occurrence can be scheduled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label('Tags'),
                const SizedBox(height: 8),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _tags)
                        TagChip(
                          text: tag,
                          onDeleted: () => setState(
                              () => _tags.removeWhere((t) => t == tag)),
                        ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add tag…',
                        ),
                        onSubmitted: _addTag,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add tag',
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Subtasks'),
                const SizedBox(height: 8),
                for (final s in _subtasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        CheckButton(
                          checked: s.done,
                          size: 19,
                          onTap: () => setState(() => s.done = !s.done),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s.text,
                            style: TextStyle(
                              decoration: s.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: s.done
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove subtask',
                          icon: const Icon(Icons.close, size: 16),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() =>
                              _subtasks.removeWhere((x) => x.id == s.id)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add subtask…',
                        ),
                        onSubmitted: _addSubtask,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add subtask',
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Pinned',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Keep at the top of lists',
                      style: TextStyle(fontSize: 12)),
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                            foregroundColor: scheme.error),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(_isEditing ? 'Save' : 'Add task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Widget _pickerButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _projectPicker(ColorScheme scheme) {
    return InputDecorator(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _projectId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Inbox'),
                ],
              ),
            ),
            for (final p in widget.state.projects)
              DropdownMenuItem(
                value: p.id,
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: projectColor(p.colorIndex)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _projectId = v ?? ''),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(labelOf(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  bool _isReminderOffset(int minutes) {
    final r = _reminderAt;
    if (r == null) return false;
    final base = _reminderBase();
    return r.difference(base).inMinutes == minutes;
  }

  bool _isTomorrowNine() {
    final r = _reminderAt;
    if (r == null) return false;
    final target = startOfDay(DateTime.now())
        .add(const Duration(days: 1, hours: 9));
    return r.isAtSameMomentAs(target);
  }

  DateTime _reminderBase() {
    final due = _dueAt;
    if (due != null) {
      return isAllDay(due)
          ? startOfDay(due).add(const Duration(hours: 9))
          : due;
    }
    return DateTime.now();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      final existing = _dueAt;
      if (existing == null || isAllDay(existing)) {
        _dueAt = endOfDay(picked);
      } else {
        _dueAt = DateTime(picked.year, picked.month, picked.day,
            existing.hour, existing.minute);
      }
    });
  }

  Future<void> _pickDueTime() async {
    final now = DateTime.now();
    final base = _dueAt;
    final current = base != null && !isAllDay(base)
        ? base
        : DateTime(now.year, now.month, now.day, 9);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      final day = base != null ? startOfDay(base) : startOfDay(now);
      _dueAt = DateTime(day.year, day.month, day.day, picked.hour, picked.minute);
    });
  }

  Future<void> _pickCustomReminder() async {
    final now = DateTime.now();
    final initial = _reminderAt ?? now.add(const Duration(hours: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;
    setState(() {
      _reminderAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);
    });
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagCtrl.clear();
  }

  void _addSubtask(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() => _subtasks.add(Subtask(id: uid(), text: text)));
    _subtaskCtrl.clear();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the task a title first.')),
      );
      return;
    }
    final existing = widget.task;
    final now = DateTime.now();
    final task = Task(
      id: existing?.id ?? uid(),
      title: title,
      notes: _notesCtrl.text.trim(),
      projectId: _projectId,
      priority: _priority,
      status: _status,
      dueAt: _dueAt,
      reminderAt: _reminderAt,
      repeat: _repeat,
      tags: _tags,
      subtasks: _subtasks,
      pinned: _pinned,
      reminderFired: existing?.reminderFired ?? false,
      createdAt: existing?.createdAt ?? now,
      completedAt:
          _status == TaskStatus.done ? (existing?.completedAt ?? now) : null,
      updatedAt: now,
    );
    if (existing == null) {
      widget.state.addTask(task);
    } else {
      widget.state.updateTask(task);
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final title = widget.state.deleteTask(widget.task!.id);
    navigator.pop();
    if (title != null) {
      messenger.showSnackBar(SnackBar(
        content: Text('Deleted “$title”'),
        duration: const Duration(seconds: 6),
        action: widget.state.canUndo
            ? SnackBarAction(
                label: 'Undo', onPressed: () => widget.state.undo())
            : null,
      ));
    }
  }

  String _priorityName(TaskPriority p) {
    switch (p) {
      case TaskPriority.none:
        return 'None';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Med';
      case TaskPriority.high:
        return 'High';
    }
  }
}
