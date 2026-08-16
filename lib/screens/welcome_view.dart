import 'package:flutter/material.dart';

import '../models/app_state.dart';

/// First-run welcome screen.
class WelcomeView extends StatelessWidget {
  const WelcomeView({
    super.key,
    required this.state,
    required this.onAddTask,
  });

  final AppState state;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.check, size: 46, color: scheme.onPrimary),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to TaskFlow',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'An advanced to-do list that lives on your device. '
                'No account, no cloud, no noise.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  _FeatureChip(icon: Icons.today_outlined, label: 'Smart lists'),
                  _FeatureChip(icon: Icons.view_kanban_outlined, label: 'Kanban board'),
                  _FeatureChip(icon: Icons.checklist, label: 'Subtasks'),
                  _FeatureChip(icon: Icons.flag_outlined, label: 'Priorities'),
                  _FeatureChip(icon: Icons.repeat, label: 'Repeating tasks'),
                  _FeatureChip(icon: Icons.alarm, label: 'Reminders'),
                  _FeatureChip(icon: Icons.local_fire_department_outlined, label: 'Streaks'),
                  _FeatureChip(icon: Icons.offline_bolt_outlined, label: 'Offline'),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      state.markWelcomeSeen();
                      onAddTask();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first task'),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.loadSampleData,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Explore with sample data'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
