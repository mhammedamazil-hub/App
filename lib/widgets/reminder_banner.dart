import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/dates.dart';

/// In-app reminder banner shown when a task's reminder time passes while
/// the app is open.
class ReminderBanner extends StatelessWidget {
  const ReminderBanner({
    super.key,
    required this.task,
    required this.now,
    required this.onOpen,
    required this.onDismiss,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final at = task.reminderAt ?? now;
    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.alarm, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.onTertiaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      '${smartDate(at, now)} · ${fmtTime(at)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onTertiaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onTertiaryContainer,
                  foregroundColor: scheme.tertiaryContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
