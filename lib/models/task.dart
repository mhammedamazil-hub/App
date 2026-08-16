import 'dart:math' as math;

import '../utils/dates.dart';

enum TaskPriority { none, low, medium, high }

enum TaskStatus { todo, doing, done }

enum RepeatRule { none, daily, weekdays, weekly, monthly, yearly }

String repeatLabel(RepeatRule r) {
  switch (r) {
    case RepeatRule.none:
      return 'Never';
    case RepeatRule.daily:
      return 'Daily';
    case RepeatRule.weekdays:
      return 'Weekdays';
    case RepeatRule.weekly:
      return 'Weekly';
    case RepeatRule.monthly:
      return 'Monthly';
    case RepeatRule.yearly:
      return 'Yearly';
  }
}

/// Computes the next occurrence of [base] under [rule], strictly after
/// [after]. Returns null when the rule is `none`.
DateTime? advanceDate(DateTime base, RepeatRule rule,
    {required DateTime after}) {
  if (rule == RepeatRule.none) return null;
  switch (rule) {
    case RepeatRule.none:
      return null;
    case RepeatRule.daily:
      var next = base.add(const Duration(days: 1));
      while (!next.isAfter(after)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    case RepeatRule.weekdays:
      var next = base;
      do {
        next = next.add(const Duration(days: 1));
      } while (next.weekday == DateTime.saturday ||
          next.weekday == DateTime.sunday);
      while (!next.isAfter(after)) {
        do {
          next = next.add(const Duration(days: 1));
        } while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday);
      }
      return next;
    case RepeatRule.weekly:
      var next = base.add(const Duration(days: 7));
      while (!next.isAfter(after)) {
        next = next.add(const Duration(days: 7));
      }
      return next;
    case RepeatRule.monthly:
      final day = base.day;
      var y = base.year;
      var m = base.month + 1;
      if (m > 12) {
        m = 1;
        y++;
      }
      var next = DateTime(y, m, math.min(day, daysInMonth(y, m)), base.hour,
          base.minute, base.second);
      while (!next.isAfter(after)) {
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
        next = DateTime(y, m, math.min(day, daysInMonth(y, m)), base.hour,
            base.minute, base.second);
      }
      return next;
    case RepeatRule.yearly:
      var y = base.year + 1;
      var next = DateTime(y, base.month, math.min(base.day, daysInMonth(y, base.month)),
          base.hour, base.minute, base.second);
      while (!next.isAfter(after)) {
        y++;
        next = DateTime(y, base.month,
            math.min(base.day, daysInMonth(y, base.month)), base.hour,
            base.minute, base.second);
      }
      return next;
  }
}

String? _dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

DateTime? _dateFromJson(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final parsed = DateTime.tryParse(v);
  return parsed?.toLocal();
}

class Subtask {
  Subtask({required this.id, required this.text, this.done = false});

  factory Subtask.fromJson(Map<String, dynamic> j) => Subtask(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        done: j['done'] == true,
      );

  String id;
  String text;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  Subtask copy() => Subtask(id: id, text: text, done: done);
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.projectId = '',
    this.priority = TaskPriority.none,
    this.status = TaskStatus.todo,
    this.dueAt,
    this.reminderAt,
    this.repeat = RepeatRule.none,
    List<String>? tags,
    List<Subtask>? subtasks,
    this.pinned = false,
    this.reminderFired = false,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
  })  : tags = tags ?? [],
        subtasks = subtasks ?? [];

  factory Task.fromJson(Map<String, dynamic> j) {
    int enumIndex(Object? v, int fallback) {
      final n = v is num ? v.toInt() : fallback;
      return n;
    }

    final priorityIdx = enumIndex(j['priority'], 0);
    final statusIdx = enumIndex(j['status'], 0);
    final repeatIdx = enumIndex(j['repeat'], 0);
    return Task(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? 'Untitled',
      notes: j['notes'] as String? ?? '',
      projectId: j['projectId'] as String? ?? '',
      priority: priorityIdx >= 0 && priorityIdx < TaskPriority.values.length
          ? TaskPriority.values[priorityIdx]
          : TaskPriority.none,
      status: statusIdx >= 0 && statusIdx < TaskStatus.values.length
          ? TaskStatus.values[statusIdx]
          : TaskStatus.todo,
      dueAt: _dateFromJson(j['dueAt']),
      reminderAt: _dateFromJson(j['reminderAt']),
      repeat: repeatIdx >= 0 && repeatIdx < RepeatRule.values.length
          ? RepeatRule.values[repeatIdx]
          : RepeatRule.none,
      tags: (j['tags'] is List)
          ? (j['tags'] as List).whereType<String>().toList()
          : [],
      subtasks: (j['subtasks'] is List)
          ? (j['subtasks'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Subtask.fromJson)
              .toList()
          : [],
      pinned: j['pinned'] == true,
      reminderFired: j['reminderFired'] == true,
      createdAt:
          _dateFromJson(j['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: _dateFromJson(j['completedAt']),
      updatedAt: _dateFromJson(j['updatedAt']),
    );
  }

  String id;
  String title;
  String notes;
  String projectId;
  TaskPriority priority;
  TaskStatus status;
  DateTime? dueAt;
  DateTime? reminderAt;
  RepeatRule repeat;
  List<String> tags;
  List<Subtask> subtasks;
  bool pinned;
  bool reminderFired;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'projectId': projectId,
        'priority': priority.index,
        'status': status.index,
        'dueAt': _dateToJson(dueAt),
        'reminderAt': _dateToJson(reminderAt),
        'repeat': repeat.index,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'pinned': pinned,
        'reminderFired': reminderFired,
        'createdAt': _dateToJson(createdAt),
        'completedAt': _dateToJson(completedAt),
        'updatedAt': _dateToJson(updatedAt),
      };

  int get doneSubtasks => subtasks.where((s) => s.done).length;

  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : doneSubtasks / subtasks.length;

  bool get hasDue => dueAt != null;

  bool get hasReminder => reminderAt != null;

  bool get isDone => status == TaskStatus.done;

  /// Overdue: not done and due date is in the past.
  bool isOverdue(DateTime now) =>
      !isDone && dueAt != null && dueAt!.isBefore(startOfDay(now));

  /// Due within the next 24 hours (and not overdue).
  bool isDueSoon(DateTime now) =>
      !isDone &&
      dueAt != null &&
      !isOverdue(now) &&
      dueAt!.isBefore(now.add(const Duration(hours: 24)));

  bool isDueToday(DateTime now) =>
      !isDone && dueAt != null && isSameDay(dueAt!, now);

  /// Deep copy used when spawning the next occurrence of a repeating task.
  Task repeatClone({required DateTime newDue, DateTime? newReminder}) => Task(
        id: '',
        title: title,
        notes: notes,
        projectId: projectId,
        priority: priority,
        status: TaskStatus.todo,
        dueAt: newDue,
        reminderAt: newReminder,
        repeat: repeat,
        tags: List.of(tags),
        subtasks: subtasks.map((s) => s.copy()).toList(),
        pinned: pinned,
        reminderFired: false,
        createdAt: DateTime.now(),
        completedAt: null,
        updatedAt: DateTime.now(),
      );

  /// Copy used by "duplicate task".
  Task duplicate() => Task(
        id: '',
        title: title,
        notes: notes,
        projectId: projectId,
        priority: priority,
        status: TaskStatus.todo,
        dueAt: dueAt,
        reminderAt: reminderAt,
        repeat: RepeatRule.none,
        tags: List.of(tags),
        subtasks: subtasks.map((s) => s.copy()).toList(),
        pinned: false,
        reminderFired: false,
        createdAt: DateTime.now(),
        completedAt: null,
        updatedAt: null,
      );
}
