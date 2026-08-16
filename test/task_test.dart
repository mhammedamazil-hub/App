import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';

void main() {
  group('Task JSON round-trip', () {
    test('preserves all fields', () {
      final task = Task(
        id: 'abc',
        title: 'Ship it',
        notes: 'notes here',
        projectId: 'p1',
        priority: TaskPriority.high,
        status: TaskStatus.doing,
        dueAt: DateTime(2026, 8, 20, 14, 30),
        reminderAt: DateTime(2026, 8, 20, 13, 0),
        repeat: RepeatRule.weekly,
        tags: ['work', 'urgent'],
        subtasks: [
          Subtask(id: 's1', text: 'one', done: true),
          Subtask(id: 's2', text: 'two'),
        ],
        pinned: true,
        reminderFired: true,
        createdAt: DateTime(2026, 8, 1, 9),
        completedAt: DateTime(2026, 8, 2, 10),
        updatedAt: DateTime(2026, 8, 3, 11),
      );

      final restored = Task.fromJson(task.toJson());

      expect(restored.id, 'abc');
      expect(restored.title, 'Ship it');
      expect(restored.notes, 'notes here');
      expect(restored.projectId, 'p1');
      expect(restored.priority, TaskPriority.high);
      expect(restored.status, TaskStatus.doing);
      expect(restored.dueAt, DateTime(2026, 8, 20, 14, 30));
      expect(restored.reminderAt, DateTime(2026, 8, 20, 13, 0));
      expect(restored.repeat, RepeatRule.weekly);
      expect(restored.tags, ['work', 'urgent']);
      expect(restored.subtasks.length, 2);
      expect(restored.subtasks.first.done, true);
      expect(restored.pinned, true);
      expect(restored.reminderFired, true);
      expect(restored.createdAt, DateTime(2026, 8, 1, 9));
      expect(restored.completedAt, DateTime(2026, 8, 2, 10));
      expect(restored.updatedAt, DateTime(2026, 8, 3, 11));
    });

    test('tolerates garbage and missing fields', () {
      final restored = Task.fromJson(const {});
      expect(restored.title, 'Untitled');
      expect(restored.priority, TaskPriority.none);
      expect(restored.status, TaskStatus.todo);
      expect(restored.repeat, RepeatRule.none);
      expect(restored.tags, isEmpty);
      expect(restored.subtasks, isEmpty);

      final weird = Task.fromJson(const {
        'priority': 99,
        'status': -3,
        'repeat': 'daily',
        'tags': 'not-a-list',
      });
      expect(weird.priority, TaskPriority.none);
      expect(weird.status, TaskStatus.todo);
      expect(weird.repeat, RepeatRule.none);
    });
  });

  group('advanceDate', () {
    test('daily', () {
      final base = DateTime(2026, 8, 16, 9);
      final next = advanceDate(base, RepeatRule.daily, after: base);
      expect(next, DateTime(2026, 8, 17, 9));
      // jumps far enough to be after `after`
      final far = advanceDate(
        base,
        RepeatRule.daily,
        after: DateTime(2026, 9, 1),
      );
      expect(far!.isAfter(DateTime(2026, 9, 1)), true);
    });

    test('weekdays skips the weekend', () {
      final friday = DateTime(2026, 8, 21, 9); // a Friday
      final next = advanceDate(friday, RepeatRule.weekdays, after: friday);
      expect(next!.weekday, DateTime.monday);
      expect(next, DateTime(2026, 8, 24, 9));
    });

    test('weekly', () {
      final base = DateTime(2026, 8, 16, 9);
      expect(
        advanceDate(base, RepeatRule.weekly, after: base),
        DateTime(2026, 8, 23, 9),
      );
    });

    test('monthly clamps end-of-month', () {
      final jan31 = DateTime(2026, 1, 31, 9);
      final next = advanceDate(jan31, RepeatRule.monthly, after: jan31);
      expect(next, DateTime(2026, 2, 28, 9));
    });

    test('yearly clamps Feb 29', () {
      final leap = DateTime(2028, 2, 29, 9);
      final next = advanceDate(leap, RepeatRule.yearly, after: leap);
      expect(next, DateTime(2029, 2, 28, 9));
    });

    test('none returns null', () {
      expect(
        advanceDate(
          DateTime(2026, 1, 1),
          RepeatRule.none,
          after: DateTime(2026, 1, 1),
        ),
        null,
      );
    });
  });

  group('overdue/due-soon logic', () {
    test('overdue when before start of today', () {
      final now = DateTime(2026, 8, 16, 12);
      final yesterday = Task(
        id: 'a',
        title: 'late',
        dueAt: DateTime(2026, 8, 15, 23, 59),
        createdAt: now,
      );
      expect(yesterday.isOverdue(now), true);

      final today = Task(
        id: 'b',
        title: 'today',
        dueAt: DateTime(2026, 8, 16, 8),
        createdAt: now,
      );
      expect(today.isOverdue(now), false);
      expect(today.isDueSoon(now), true);
      expect(today.isDueToday(now), true);

      final done = Task(
        id: 'c',
        title: 'done late',
        status: TaskStatus.done,
        dueAt: DateTime(2026, 8, 15, 23, 59),
        createdAt: now,
      );
      expect(done.isOverdue(now), false);
    });
  });

  group('subtask progress', () {
    test('counts and progress', () {
      final task = Task(
        id: 'a',
        title: 'x',
        createdAt: DateTime.now(),
        subtasks: [
          Subtask(id: '1', text: 'a', done: true),
          Subtask(id: '2', text: 'b'),
          Subtask(id: '3', text: 'c'),
        ],
      );
      expect(task.doneSubtasks, 1);
      expect(task.subtaskProgress, closeTo(1 / 3, 0.001));
      expect(
        Task(id: 'b', title: 'y', createdAt: DateTime.now()).subtaskProgress,
        0,
      );
    });
  });
}
