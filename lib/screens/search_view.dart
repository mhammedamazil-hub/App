import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/task.dart';
import '../widgets/empty_state.dart';
import 'task_list_view.dart';

/// Live search across titles, notes and tags.
class SearchView extends StatelessWidget {
  const SearchView({
    super.key,
    required this.state,
    required this.query,
    required this.now,
    required this.onOpenTask,
  });

  final AppState state;
  final String query;
  final DateTime now;
  final void Function(Task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final results = state.searchTasks(query);
    final scheme = Theme.of(context).colorScheme;

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No matches',
        message:
            'Nothing found for “${query.trim()}”. Try a different '
            'keyword — titles, notes and tags are searched.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'} '
            'for “${query.trim()}”',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: TaskListView(
            state: state,
            tasks: results,
            now: now,
            showProject: true,
            onOpenTask: onOpenTask,
            emptyState: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
