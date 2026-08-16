import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/backup.dart';
import '../services/storage.dart';
import '../utils/dates.dart';
import '../utils/ids.dart';
import 'project.dart';
import 'settings.dart';
import 'task.dart';

/// Result of completing a task — carries the next occurrence when the task
/// repeats.
class CompletionResult {
  CompletionResult(this.completed, {this.next});

  final Task completed;
  final Task? next;
}

class ProjectProgress {
  ProjectProgress({
    required this.project,
    required this.open,
    required this.done,
  });

  final Project project;
  final int open;
  final int done;

  int get total => open + done;

  double get rate => total == 0 ? 0 : done / total;
}

/// Central application state: tasks, projects, settings, undo and
/// persistence. Pure Dart (no Flutter imports beyond `foundation`), so it is
/// fully unit-testable.
class AppState extends ChangeNotifier {
  AppState({Storage? storage}) : _storage = storage ?? createStorage();

  final Storage _storage;

  List<Project> projects = [];
  List<Task> tasks = [];
  Settings settings = Settings();

  bool loaded = false;
  String? loadError;
  String? saveError;

  Timer? _saveTimer;
  bool _dirty = false;

  // Single-level undo for destructive operations.
  List<Project>? _undoProjects;
  List<Task>? _undoTasks;
  String _undoLabel = '';
  bool get canUndo => _undoTasks != null;
  String get undoLabel => _undoLabel;

  // ---------------------------------------------------------------- loading

  Future<void> init() async {
    String? raw;
    try {
      raw = await _storage.load();
    } catch (e) {
      loadError = 'Could not read saved data: $e';
    }
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          settings = Settings.fromJson(
            data['settings'] is Map<String, dynamic>
                ? data['settings'] as Map<String, dynamic>
                : const {},
          );
          projects = _parseProjects(data['projects']);
          tasks = _parseTasks(data['tasks']);
        }
      } catch (e) {
        loadError = 'Saved data could not be read ($e). Starting fresh.';
      }
    }
    loaded = true;
    notifyListeners();
  }

  List<Project> _parseProjects(dynamic list) {
    final out = <Project>[];
    if (list is List) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            out.add(Project.fromJson(e));
          } catch (_) {}
        }
      }
    }
    return out;
  }

  List<Task> _parseTasks(dynamic list) {
    final out = <Task>[];
    if (list is List) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            out.add(Task.fromJson(e));
          } catch (_) {}
        }
      }
    }
    return out;
  }

  // -------------------------------------------------------------- persistence

  Map<String, dynamic> toJson() => {
    'version': 1,
    'settings': settings.toJson(),
    'projects': projects.map((p) => p.toJson()).toList(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  void _touch() {
    _dirty = true;
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      saveNow();
    });
  }

  Future<void> saveNow() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _storage.save(jsonEncode(toJson()));
      saveError = null;
    } catch (e) {
      saveError = 'Saving failed: $e';
      _dirty = true;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------- undo

  void _snapshotUndo(String label) {
    _undoProjects = projects.map((p) => p.copyWith()).toList();
    _undoTasks = tasks.map((t) => _shallowCopyTask(t)).toList();
    _undoLabel = label;
  }

  void undo() {
    if (!canUndo) return;
    projects = _undoProjects!;
    tasks = _undoTasks!;
    _undoProjects = null;
    _undoTasks = null;
    _undoLabel = '';
    _touch();
  }

  // ------------------------------------------------------------------- tasks

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void addTask(Task t) {
    tasks.insert(0, t);
    _touch();
  }

  void updateTask(Task updated) {
    final i = tasks.indexWhere((t) => t.id == updated.id);
    if (i < 0) return;
    tasks[i] = updated;
    _touch();
  }

  /// Deletes a task (undoable). Returns its title for snackbars, or null.
  String? deleteTask(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    _snapshotUndo('Task deleted');
    final removed = tasks.removeAt(i);
    _touch();
    return removed.title;
  }

  /// Completes a task; spawns the next occurrence for repeating tasks.
  CompletionResult? completeTask(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    final t = tasks[i];
    if (t.isDone) return null;
    final now = DateTime.now();
    final completed = _shallowCopyTask(t);
    completed
      ..status = TaskStatus.done
      ..completedAt = now
      ..updatedAt = now
      ..reminderFired = true;
    tasks[i] = completed;
    Task? next;
    if (t.repeat != RepeatRule.none && t.dueAt != null) {
      final nextDue = advanceDate(t.dueAt!, t.repeat, after: now);
      if (nextDue != null) {
        final delta = nextDue.difference(t.dueAt!);
        next = t.repeatClone(
          newDue: nextDue,
          newReminder: t.reminderAt != null ? t.reminderAt!.add(delta) : null,
        )..id = uid();
        tasks.insert(0, next);
      }
    }
    _touch();
    return CompletionResult(completed, next: next);
  }

  /// Reopens a completed task.
  void reopenTask(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = tasks[i];
    if (!t.isDone) return;
    final updated = _shallowCopyTask(t)
      ..status = TaskStatus.todo
      ..completedAt = null
      ..updatedAt = DateTime.now();
    tasks[i] = updated;
    _touch();
  }

  void setStatus(String id, TaskStatus status) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = tasks[i];
    if (t.status == status) return;
    final now = DateTime.now();
    final updated = _shallowCopyTask(t)
      ..status = status
      ..updatedAt = now
      ..completedAt = status == TaskStatus.done ? (t.completedAt ?? now) : null;
    tasks[i] = updated;
    _touch();
  }

  void togglePin(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i] = _shallowCopyTask(tasks[i])..pinned = !tasks[i].pinned;
    _touch();
  }

  void moveTask(String id, String projectId) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i] = _shallowCopyTask(tasks[i])..projectId = projectId;
    _touch();
  }

  /// Moves [id] directly before [beforeId] (or to the end when null).
  /// Combined with [setStatus] this powers the Kanban drag & drop.
  void moveTaskBefore(String id, String? beforeId) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final task = tasks.removeAt(i);
    var insertAt = tasks.length;
    if (beforeId != null) {
      final j = tasks.indexWhere((t) => t.id == beforeId);
      if (j >= 0) insertAt = j;
    }
    tasks.insert(insertAt, task);
    _touch();
  }

  void duplicateTask(String id) {
    final t = taskById(id);
    if (t == null) return;
    final copy = t.duplicate()..id = uid();
    tasks.insert(0, copy);
    _touch();
  }

  void markReminderFired(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i] = _shallowCopyTask(tasks[i])..reminderFired = true;
    _touch();
  }

  // --------------------------------------------------------------- subtasks

  void addSubtask(String taskId, String text) {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0 || text.trim().isEmpty) return;
    final updated = _shallowCopyTask(tasks[i]);
    updated.subtasks.add(Subtask(id: uid(), text: text.trim()));
    tasks[i] = updated;
    _touch();
  }

  void toggleSubtask(String taskId, String subId) {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final updated = _shallowCopyTask(tasks[i]);
    for (final s in updated.subtasks) {
      if (s.id == subId) {
        s.done = !s.done;
        break;
      }
    }
    tasks[i] = updated;
    _touch();
  }

  void removeSubtask(String taskId, String subId) {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final updated = _shallowCopyTask(tasks[i]);
    updated.subtasks.removeWhere((s) => s.id == subId);
    tasks[i] = updated;
    _touch();
  }

  // --------------------------------------------------------------- projects

  Project addProject(String name, {int colorIndex = 0, int iconIndex = 0}) {
    final p = Project(
      id: uid(),
      name: name.trim(),
      colorIndex: colorIndex,
      iconIndex: iconIndex,
    );
    projects.add(p);
    _touch();
    return p;
  }

  void updateProject(Project p) {
    final i = projects.indexWhere((x) => x.id == p.id);
    if (i < 0) return;
    projects[i] = p;
    _touch();
  }

  /// Deletes a project; its tasks move to the Inbox. Undoable.
  void deleteProject(String id) {
    final i = projects.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _snapshotUndo('Project deleted');
    projects.removeAt(i);
    for (var j = 0; j < tasks.length; j++) {
      if (tasks[j].projectId == id) {
        tasks[j] = _shallowCopyTask(tasks[j])..projectId = '';
      }
    }
    _touch();
  }

  Project? projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ----------------------------------------------------------------- queries

  List<Task> get openTasks =>
      tasks.where((t) => !t.isDone).toList()..sort(_compareTasks);

  List<Task> get completedTasks =>
      tasks.where((t) => t.isDone).toList()..sort(_compareDoneTasks);

  List<Task> openIn(String projectId) =>
      openTasks.where((t) => t.projectId == projectId).toList();

  List<Task> completedIn(String projectId) =>
      completedTasks.where((t) => t.projectId == projectId).toList();

  List<Task> overdueTasks(DateTime now) =>
      openTasks.where((t) => t.isOverdue(now)).toList()
        ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

  List<Task> tasksDueToday(DateTime now) =>
      openTasks.where((t) => t.isDueToday(now)).toList();

  List<Task> completedToday(DateTime now) => completedTasks
      .where((t) => t.completedAt != null && isSameDay(t.completedAt!, now))
      .toList();

  /// Open tasks due within the next [days] days (starting today).
  List<Task> upcomingTasks(DateTime now, {int days = 14}) {
    final from = startOfDay(now);
    final to = startOfDay(now).add(Duration(days: days + 1));
    return openTasks
        .where(
          (t) =>
              t.dueAt != null &&
              !t.dueAt!.isBefore(from) &&
              t.dueAt!.isBefore(to),
        )
        .toList();
  }

  /// Open tasks due beyond [days] days, plus open tasks without a due date.
  List<Task> laterTasks(DateTime now, {int days = 14}) {
    final to = startOfDay(now).add(Duration(days: days + 1));
    return openTasks
        .where((t) => t.dueAt == null || !t.dueAt!.isBefore(to))
        .toList();
  }

  List<Task> pendingReminders(DateTime now) =>
      tasks
          .where(
            (t) =>
                t.reminderAt != null &&
                !t.reminderFired &&
                !t.isDone &&
                t.reminderAt!.isBefore(now),
          )
          .toList()
        ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));

  List<Task> searchTasks(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return tasks
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.notes.toLowerCase().contains(q) ||
              t.tags.any((tag) => tag.toLowerCase().contains(q)),
        )
        .toList()
      ..sort(_compareTasks);
  }

  Set<String> allTags() {
    final tags = <String>{};
    for (final t in tasks) {
      tags.addAll(t.tags);
    }
    return tags;
  }

  int _compareTasks(Task a, Task b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final ad = a.dueAt;
    final bd = b.dueAt;
    if (ad != null && bd != null) {
      final c = ad.compareTo(bd);
      if (c != 0) return c;
    } else if (ad != null) {
      return -1;
    } else if (bd != null) {
      return 1;
    }
    final p = b.priority.index.compareTo(a.priority.index);
    if (p != 0) return p;
    return b.createdAt.compareTo(a.createdAt);
  }

  int _compareDoneTasks(Task a, Task b) {
    final ac = a.completedAt ?? a.updatedAt ?? a.createdAt;
    final bc = b.completedAt ?? b.updatedAt ?? b.createdAt;
    return bc.compareTo(ac);
  }

  // ------------------------------------------------------------------- stats

  int get totalTasks => tasks.length;

  int get openCount => totalTasks - completedCount;

  int get completedCount => tasks.where((t) => t.isDone).length;

  double get completionRate =>
      totalTasks == 0 ? 0 : completedCount / totalTasks;

  int overdueCount(DateTime now) => overdueTasks(now).length;

  int dueTodayCount(DateTime now) => tasksDueToday(now).length;

  /// Consecutive days with at least one completed task, ending today or
  /// yesterday.
  int currentStreak(DateTime now) {
    final days = <String>{};
    for (final t in tasks) {
      final at = t.completedAt;
      if (at != null) {
        days.add('${at.year}-${at.month}-${at.day}');
      }
    }
    var streak = 0;
    var day = startOfDay(now);
    if (!days.contains('${day.year}-${day.month}-${day.day}')) {
      day = day.subtract(const Duration(days: 1));
    }
    while (days.contains('${day.year}-${day.month}-${day.day}')) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Tasks completed per day over the last 7 days (oldest first).
  List<int> completedLast7Days(DateTime now) {
    final counts = List<int>.filled(7, 0);
    for (final t in tasks) {
      final at = t.completedAt;
      if (at == null) continue;
      final diff = dayDiff(at, now);
      if (diff <= 0 && diff > -7) {
        counts[6 + diff]++;
      }
    }
    return counts;
  }

  List<ProjectProgress> projectProgress() {
    final out = <ProjectProgress>[];
    for (final p in projects) {
      var open = 0;
      var done = 0;
      for (final t in tasks) {
        if (t.projectId != p.id) continue;
        if (t.isDone) {
          done++;
        } else {
          open++;
        }
      }
      out.add(ProjectProgress(project: p, open: open, done: done));
    }
    return out;
  }

  // ------------------------------------------------------------------ backup

  String exportJson() => jsonEncode(toJson());

  Future<String> exportBackupNow() async {
    try {
      return await exportBackup(exportJson(), now: DateTime.now());
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Replaces all data with the parsed backup. Undoable. Returns a summary.
  String importJson(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Not a TaskFlow backup file.');
    }
    if (data['tasks'] is! List) {
      throw const FormatException('Backup is missing its task list.');
    }
    _snapshotUndo('Data replaced');
    projects = _parseProjects(data['projects']);
    tasks = _parseTasks(data['tasks']);
    if (data['settings'] is Map<String, dynamic>) {
      settings = Settings.fromJson(data['settings'] as Map<String, dynamic>);
    }
    _touch();
    return 'Imported ${tasks.length} tasks in ${projects.length} projects.';
  }

  Future<String?> importBackupNow() async {
    try {
      final raw = await pickImportFile();
      if (raw == null) return null;
      return importJson(raw);
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }

  void clearAll() {
    _snapshotUndo('All data cleared');
    tasks = [];
    projects = [];
    _touch();
  }

  // ------------------------------------------------------------------ sample

  void markWelcomeSeen() {
    settings.welcomeSeen = true;
    _touch();
  }

  /// Notifies listeners and persists after a settings-only change
  /// (theme, accent color, ...).
  void notifySettingsChanged() {
    _touch();
  }

  /// Loads a small set of demonstrative data (relative to now).
  void loadSampleData() {
    final now = DateTime.now();
    final today = startOfDay(now);
    Task due({required String title, DateTime? at, String? notes}) => Task(
      id: uid(),
      title: title,
      notes: notes ?? '',
      dueAt: at,
      createdAt: now,
      updatedAt: now,
    );

    final work = addProject('Work', colorIndex: 3, iconIndex: 1);
    final personal = addProject('Personal', colorIndex: 6, iconIndex: 2);

    tasks.add(
      due(
        title: 'Open a project and switch to the Kanban board',
        notes: 'Use the view toggle in the project header.',
        at: today.add(const Duration(hours: 11, minutes: 30)),
      ),
    );
    final tour = Task(
      id: uid(),
      title: 'Swipe right on a task to complete it',
      notes: 'Completing tasks builds your streak.',
      priority: TaskPriority.low,
      dueAt: today.add(const Duration(hours: 15)),
      createdAt: now,
      updatedAt: now,
      subtasks: [
        Subtask(id: uid(), text: 'Try the list view', done: true),
        Subtask(id: uid(), text: 'Try the Kanban board'),
      ],
      tags: ['getting-started'],
    );
    tasks.add(tour);
    tasks.add(
      Task(
        id: uid(),
        title: 'Swipe left to delete (you can undo)',
        priority: TaskPriority.medium,
        dueAt: today.add(const Duration(hours: 18)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'Weekly review — completes into a new occurrence',
        notes: 'This task repeats every week.',
        projectId: work.id,
        repeat: RepeatRule.weekly,
        dueAt: today.add(const Duration(days: 2, hours: 9)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'Plan next week’s goals',
        projectId: work.id,
        priority: TaskPriority.medium,
        dueAt: today.subtract(const Duration(days: 1, hours: 3)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        tags: ['work', 'planning'],
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'Groceries for the week',
        projectId: personal.id,
        priority: TaskPriority.low,
        dueAt: today.add(const Duration(days: 3, hours: 17)),
        createdAt: now,
        updatedAt: now,
        subtasks: [
          Subtask(id: uid(), text: 'Milk', done: true),
          Subtask(id: uid(), text: 'Eggs'),
          Subtask(id: uid(), text: 'Coffee'),
        ],
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'Draft the blog post outline',
        projectId: work.id,
        notes: 'Focus on the intro and three key sections.',
        status: TaskStatus.doing,
        dueAt: today.add(const Duration(days: 6, hours: 10)),
        createdAt: now,
        updatedAt: now,
        tags: ['writing'],
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'Book a dentist appointment',
        projectId: personal.id,
        priority: TaskPriority.high,
        dueAt: today.add(const Duration(days: 5, hours: 12)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    tasks.add(
      Task(
        id: uid(),
        title: 'I have a reminder set — it fires in-app',
        dueAt: today.add(const Duration(hours: 2)),
        reminderAt: now.add(const Duration(seconds: 45)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    // Seed the streak with a couple of completed tasks.
    final doneSeed = Task(
      id: uid(),
      title: 'Set up TaskFlow',
      status: TaskStatus.done,
      completedAt: now.subtract(const Duration(hours: 5)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    tasks.add(doneSeed);
    final doneSeed2 = Task(
      id: uid(),
      title: 'Read the getting-started notes',
      status: TaskStatus.done,
      completedAt: now.subtract(const Duration(days: 1, hours: 2)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    tasks.add(doneSeed2);

    markWelcomeSeen();
    _touch();
  }

  // ----------------------------------------------------------------- helpers

  /// Copies top-level fields; nested lists are shared on purpose.
  Task _shallowCopyTask(Task t) => Task(
    id: t.id,
    title: t.title,
    notes: t.notes,
    projectId: t.projectId,
    priority: t.priority,
    status: t.status,
    dueAt: t.dueAt,
    reminderAt: t.reminderAt,
    repeat: t.repeat,
    tags: List.of(t.tags),
    subtasks: t.subtasks,
    pinned: t.pinned,
    reminderFired: t.reminderFired,
    createdAt: t.createdAt,
    completedAt: t.completedAt,
    updatedAt: t.updatedAt,
  );
}
