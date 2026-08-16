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
  testWidgets('TaskFlow shell boots to the welcome screen', (tester) async {
    final state = AppState(storage: MemoryStorage());
    state.loaded = true; // skip the async disk load

    await tester.pumpWidget(MaterialApp(home: TaskFlowShell(state: state)));
    await tester.pump(const Duration(seconds: 1));

    // The shell mounted, and with no data the welcome screen is shown.
    expect(find.byType(TaskFlowShell), findsOneWidget);
    expect(find.text('Welcome to TaskFlow'), findsOneWidget);
  });
}
