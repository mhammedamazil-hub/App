import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/app_state.dart';
import 'package:taskflow/screens/shell.dart';
import 'package:taskflow/services/storage.dart';

/// In-memory storage so the widget test is hermetic.
class MemoryStorage implements Storage {
  @override
  Future<String?> load() async => null;

  @override
  Future<void> save(String data) async {}
}

void main() {
  testWidgets('TaskFlow boots to the welcome screen and opens the editor', (
    tester,
  ) async {
    final state = AppState(storage: MemoryStorage());
    state.loaded = true; // skip the async disk load

    await tester.pumpWidget(MaterialApp(home: TaskFlowShell(state: state)));
    await tester.pump();

    // First run with no data: the welcome screen is shown.
    expect(find.text('Welcome to TaskFlow'), findsOneWidget);
    expect(find.text('Create your first task'), findsOneWidget);

    // Tapping the CTA opens the new-task editor sheet.
    await tester.tap(find.text('Create your first task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New task'), findsOneWidget);
  });
}
