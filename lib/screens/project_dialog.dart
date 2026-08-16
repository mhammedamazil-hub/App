import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../theme.dart';
import '../widgets/badges.dart';

/// Create or edit a project.
Future<Project?> showProjectDialog(
  BuildContext context,
  AppState state, {
  Project? project,
}) {
  return showDialog<Project>(
    context: context,
    builder: (context) => _ProjectDialog(state: state, project: project),
  );
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({required this.state, this.project});

  final AppState state;
  final Project? project;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _nameCtrl;
  late int _colorIndex;
  late int _iconIndex;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project?.name ?? '');
    _colorIndex = widget.project?.colorIndex ?? 0;
    _iconIndex = widget.project?.iconIndex ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.project != null;
    return AlertDialog(
      title: Text(editing ? 'Edit project' : 'New project'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProjectAvatar(
                  colorIndex: _colorIndex,
                  iconIndex: _iconIndex,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: !editing,
                    decoration: const InputDecoration(hintText: 'Project name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < projectColors.length; i++)
                  InkWell(
                    onTap: () => setState(() => _colorIndex = i),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: projectColors[i],
                        shape: BoxShape.circle,
                        border: _colorIndex == i
                            ? Border.all(color: scheme.onSurface, width: 2.5)
                            : null,
                      ),
                      child: _colorIndex == i
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < projectIcons.length; i++)
                  InkWell(
                    onTap: () => setState(() => _iconIndex = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _iconIndex == i
                            ? projectColor(_colorIndex).withValues(alpha: 0.2)
                            : scheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: _iconIndex == i
                            ? Border.all(
                                color: projectColor(_colorIndex),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Icon(
                        projectIcon(i),
                        size: 18,
                        color: _iconIndex == i
                            ? projectColor(_colorIndex)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the project a name first.')),
      );
      return;
    }
    final existing = widget.project;
    Project result;
    if (existing == null) {
      result = widget.state.addProject(
        name,
        colorIndex: _colorIndex,
        iconIndex: _iconIndex,
      );
    } else {
      result = existing.copyWith(
        name: name,
        colorIndex: _colorIndex,
        iconIndex: _iconIndex,
      );
      widget.state.updateProject(result);
    }
    Navigator.of(context).pop(result);
  }
}
