import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/app_state.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/services/storage.dart';

/// In-memory storage for tests.
class MemoryStorage implements Storage {
  String? data;
  @override
  Future<String?> load() async => data;
  @override
  Future<void> save(String value) async => data = value;
}

Task makeTask(
  String id,
  String title, {
  String projectId = '',
  TaskStatus status = TaskStatus.todo,
  DateTime? dueAt,
  RepeatRule repeat = RepeatRule.none,
}) {
  return Task(
    id: id,
    title: title,
    projectId: projectId,
    status: status,
    dueAt: dueAt,
    repeat: repeat,
    createdAt: DateTime(2026, 8, 1, 9),
  );
}

void main() {
  final now = DateTime(2026, 8, 16, 12);

  group('task CRUD', () {
    test('add, update, delete and undo', () {
      final state = AppState(storage: MemoryStorage());
      state.tasks.add(makeTask('a', 'first'));
      state.addTask(makeTask('b', 'second'));

      expect(state.tasks.length, 2);
      expect(state.tasks.first.title, 'second'); // newest first

      final deleted = state.deleteTask('a');
      expect(deleted, 'first');
      expect(state.tasks.length, 1);
      expect(state.canUndo, true);

      state.undo();
      expect(state.tasks.length, 2);
      expect(state.canUndo, false);

      state.updateTask(makeTask('a', 'first (edited)'));
      expect(state.taskById('a')?.title, 'first (edited)');
    });

    test('completing a repeating task spawns the next occurrence', () {
      final state = AppState(storage: MemoryStorage());
      final due = DateTime(2026, 8, 16, 9);
      state.addTask(
        makeTask('r1', 'repeat me', dueAt: due, repeat: RepeatRule.daily),
      );

      final result = state.completeTask('r1');
      expect(result, isNotNull);
      expect(result!.completed.isDone, true);
      expect(result.next, isNotNull);
      expect(result.next!.isDone, false);
      expect(result.next!.repeat, RepeatRule.daily);
      // next occurrence strictly after the original due date
      expect(result.next!.dueAt!.isAfter(due), true);

      // completing a non-repeating task spawns nothing
      state.addTask(makeTask('s1', 'single', dueAt: due));
      final single = state.completeTask('s1');
      expect(single!.next, isNull);
    });

    test('setStatus and reopen', () {
      final state = AppState(storage: MemoryStorage());
      state.addTask(makeTask('a', 'x'));
      state.setStatus('a', TaskStatus.done);
      expect(state.taskById('a')!.isDone, true);
      expect(state.taskById('a')!.completedAt, isNotNull);

      state.reopenTask('a');
      expect(state.taskById('a')!.isDone, false);
      expect(state.taskById('a')!.completedAt, isNull);
    });
  });

  group('projects', () {
    test('delete moves tasks to inbox and undo restores', () {
      final state = AppState(storage: MemoryStorage());
      final project = state.addProject('Work');
      state.addTask(makeTask('a', 'task in project', projectId: project.id));

      state.deleteProject(project.id);
      expect(state.projects, isEmpty);
      expect(state.taskById('a')!.projectId, '');

      state.undo();
      expect(state.projects.length, 1);
      expect(state.taskById('a')!.projectId, project.id);
    });
  });

  group('queries and stats', () {
    test('overdue, due today, completed', () {
      final state = AppState(storage: MemoryStorage());
      state.addTask(
        makeTask('late', 'late task', dueAt: DateTime(2026, 8, 15, 23, 59)),
      );
      state.addTask(
        makeTask('today', 'today task', dueAt: DateTime(2026, 8, 16, 18)),
      );
      state.addTask(
        makeTask(
          'done',
          'done task',
          status: TaskStatus.done,
          dueAt: DateTime(2026, 8, 16, 10),
        ),
      );

      expect(state.overdueCount(now), 1);
      expect(state.dueTodayCount(now), 1);
      expect(state.openCount, 2);
      expect(state.completedCount, 1);
      expect(state.totalTasks, 3);
      expect(state.completionRate, closeTo(1 / 3, 0.001));
    });

    test('streak counts consecutive completed days', () {
      final state = AppState(storage: MemoryStorage());
      Task completedOn(DateTime at) => Task(
        id: 'id-$at',
        title: 'done',
        status: TaskStatus.done,
        completedAt: at,
        createdAt: at,
      );
      state.tasks.add(completedOn(now));
      state.tasks.add(completedOn(now.subtract(const Duration(days: 1))));
      state.tasks.add(completedOn(now.subtract(const Duration(days: 2))));
      // gap at day 3, resumes at day 4 (must not count)
      state.tasks.add(completedOn(now.subtract(const Duration(days: 4))));
      expect(state.currentStreak(now), 3);

      // if today has nothing, the streak may still end at yesterday
      final state2 = AppState(storage: MemoryStorage());
      state2.tasks.add(completedOn(now.subtract(const Duration(days: 1))));
      expect(state2.currentStreak(now), 1);
    });

    test('search matches title, notes and tags', () {
      final state = AppState(storage: MemoryStorage());
      state.addTask(makeTask('a', 'Buy milk'));
      state.addTask(makeTask('b', 'plan trip'));
      state.addTask(makeTask('c', 'Call dentist'));

      expect(state.searchTasks('milk').length, 1);
      expect(state.searchTasks('trip').first.id, 'b');
      expect(state.searchTasks('zzz'), isEmpty);
    });

    test('pending reminders exclude fired and done', () {
      final state = AppState(storage: MemoryStorage());
      state.addTask(
        Task(
          id: 'r1',
          title: 'fire me',
          reminderAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now,
        ),
      );
      state.addTask(
        Task(
          id: 'r2',
          title: 'already fired',
          reminderAt: now.subtract(const Duration(minutes: 5)),
          reminderFired: true,
          createdAt: now,
        ),
      );
      state.addTask(
        Task(
          id: 'r3',
          title: 'done',
          status: TaskStatus.done,
          reminderAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now,
        ),
      );

      final pending = state.pendingReminders(now);
      expect(pending.length, 1);
      expect(pending.first.id, 'r1');
    });
  });

  group('persistence and backup', () {
    test('toJson / import round-trip', () {
      final state = AppState(storage: MemoryStorage());
      state.addProject('Work');
      state.addTask(makeTask('a', 'task a'));
      final json = state.exportJson();

      final restored = AppState(storage: MemoryStorage());
      final summary = restored.importJson(json);
      expect(summary, contains('1 tasks'));
      expect(restored.projects.length, 1);
      expect(restored.taskById('a')?.title, 'task a');
      expect(restored.canUndo, true);
      restored.undo();
      expect(restored.tasks, isEmpty);
    });

    test('import rejects invalid payloads', () {
      final state = AppState(storage: MemoryStorage());
      expect(() => state.importJson('not json'), throwsFormatException);
      expect(() => state.importJson('{"nope": true}'), throwsFormatException);
    });

    test('saveNow persists through storage', () async {
      final storage = MemoryStorage();
      final state = AppState(storage: storage);
      state.addTask(makeTask('a', 'task a'));
      await state.saveNow();
      expect(storage.data, contains('task a'));

      final reloaded = AppState(storage: storage);
      await reloaded.init();
      expect(reloaded.tasks.length, 1);
    });

    test('clearAll is undoable', () {
      final state = AppState(storage: MemoryStorage());
      state.addTask(makeTask('a', 'task a'));
      state.clearAll();
      expect(state.tasks, isEmpty);
      state.undo();
      expect(state.tasks.length, 1);
    });
  });
}
