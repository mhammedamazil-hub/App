import 'package:flutter/material.dart';

import 'models/app_state.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() {
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});

  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _state.init();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seed = accentSeeds[_state.settings.accentIndex % accentSeeds.length];
    ThemeMode themeMode;
    if (_state.settings.themeMode == 1) {
      themeMode = ThemeMode.light;
    } else if (_state.settings.themeMode == 2) {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(seed: seed, brightness: Brightness.light),
      darkTheme: buildTheme(seed: seed, brightness: Brightness.dark),
      themeMode: themeMode,
      home: _state.loaded
          ? TaskFlowShell(state: _state)
          : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary,
                    scheme.primary.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check, size: 36, color: scheme.onPrimary),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
