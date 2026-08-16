import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined, size: 16),
                  ),
                ],
                selected: {state.settings.themeMode.clamp(0, 2)},
                onSelectionChanged: (selection) {
                  state.settings.themeMode = selection.first;
                  state.notifySettingsChanged();
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),
              Text(
                'Accent color',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < accentSeeds.length; i++)
                    _ColorDot(
                      color: accentSeeds[i],
                      selected: state.settings.accentIndex == i,
                      onTap: () {
                        state.settings.accentIndex = i;
                        state.notifySettingsChanged();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Your data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Everything is stored on this device — no account, no cloud. '
                'Export a backup regularly and keep it somewhere safe.',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (state.loadError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.loadError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              if (state.saveError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.saveError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final message = await state.exportBackupNow();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export backup'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Import backup'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _loadSample(context),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Load sample data'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _clearAll(context),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Clear all data'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check, color: scheme.onPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TaskFlow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Version 1.0.0 — advanced to-do list',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Smart lists · projects · Kanban board · subtasks · priorities · '
                'tags · repeating tasks · reminders · streaks · offline storage '
                '· backup & restore. Built with Flutter and zero third-party '
                'dependencies.',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Keyboard: Ctrl+N new task · Ctrl+K search · Esc clear search',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces all current tasks and projects with the backup. '
          'You can undo afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final summary = await state.importBackupNow();
      if (summary == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Import cancelled.')),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary),
          duration: const Duration(seconds: 6),
          action: state.canUndo
              ? SnackBarAction(label: 'Undo', onPressed: () => state.undo())
              : null,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _loadSample(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load sample data?'),
        content: const Text(
          'Adds example projects and tasks so you can explore the app. '
          'Your current data stays untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add samples'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    state.loadSampleData();
    messenger.showSnackBar(
      const SnackBar(content: Text('Sample data loaded. Enjoy exploring!')),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'Every task and project will be permanently removed from this '
          'device. Consider exporting a backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    state.clearAll();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('All data cleared.'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Undo', onPressed: () => state.undo()),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
