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
  testWidgets(
    'TaskFlow boots to the welcome screen and the FAB opens the editor',
    (tester) async {
      final state = AppState(storage: MemoryStorage());
      state.loaded = true; // skip the async disk load

      await tester.pumpWidget(MaterialApp(home: TaskFlowShell(state: state)));
      await tester.pump();

      // First run with no data: the welcome screen is shown.
      expect(find.text('Welcome to TaskFlow'), findsOneWidget);

      // The floating action button is always visible and opens the editor.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('New task'), findsOneWidget);
    },
  );
}
