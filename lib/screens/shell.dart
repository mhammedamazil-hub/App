import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/sidebar.dart';
import 'project_dialog.dart';
import 'project_view.dart';
import 'projects_page.dart';
import 'search_view.dart';
import 'settings_view.dart';
import 'stats_view.dart';
import 'task_editor_sheet.dart';
import 'task_list_view.dart';
import 'today_view.dart';
import 'upcoming_view.dart';
import 'welcome_view.dart';

class TaskFlowShell extends StatefulWidget {
  const TaskFlowShell({super.key, required this.state});

  final AppState state;

  @override
  State<TaskFlowShell> createState() => _TaskFlowShellState();
}

class _TaskFlowShellState extends State<TaskFlowShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _editorOpen = false;

  SmartList _selectedSmart = SmartList.today;
  String? _projectId;
  ProjectViewMode _projectMode = ProjectViewMode.list;
  String _query = '';
  Task? _bannerTask;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _reminderTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkReminders();
    });
    Timer(const Duration(seconds: 2), _checkReminders);
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _checkReminders() {
    if (!mounted) return;
    if (_bannerTask == null) {
      final pending = widget.state.pendingReminders(DateTime.now());
      if (pending.isNotEmpty) {
        setState(() => _bannerTask = pending.first);
      }
    }
  }

  AppState get state => widget.state;

  // ------------------------------------------------------------- navigation

  void _selectSmart(SmartList list) {
    setState(() {
      _selectedSmart = list;
      _projectId = null;
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        _scaffoldKey.currentState?.closeDrawer();
      }
    });
  }

  void _selectProject(Project project) {
    setState(() {
      _projectId = project.id;
      _selectedSmart = SmartList.today;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _clearProject() {
    setState(() => _projectId = null);
  }

  // ------------------------------------------------------------------- tasks

  Future<void> _newTask({TaskStatus? status, String? projectId}) async {
    if (_editorOpen) return;
    _editorOpen = true;
    try {
      await showTaskEditor(
        context,
        state,
        presetProjectId: projectId ?? _projectId,
        presetStatus: status,
      );
    } finally {
      _editorOpen = false;
    }
  }

  Future<void> _openTask(Task task) async {
    if (_editorOpen) return;
    _editorOpen = true;
    try {
      await showTaskEditor(context, state, task: task);
    } finally {
      _editorOpen = false;
    }
  }

  // ---------------------------------------------------------------- projects

  Future<void> _addProject() async {
    final project = await showProjectDialog(context, state);
    if (project != null) {
      _selectProject(project);
    }
  }

  Future<void> _editProject(Project project) async {
    await showProjectDialog(context, state, project: project);
  }

  Future<void> _deleteProject(Project project) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${project.name}”?'),
        content: const Text(
            'Its tasks move to the Inbox. You can undo this.'),
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
            child: const Text('Delete project'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    state.deleteProject(project.id);
    setState(() {
      if (_projectId == project.id) _projectId = null;
    });
    messenger.showSnackBar(SnackBar(
      content: Text('Project “${project.name}” deleted.'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(label: 'Undo', onPressed: () => state.undo()),
    ));
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (!_editorOpen) _newTask();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _searchFocus.requestFocus(),
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isWide ? null : _drawer(),
        body: Row(
          children: [
            if (isWide)
              SizedBox(
                width: 236,
                child: Sidebar(
                  state: state,
                  now: DateTime.now(),
                  selectedSmart: _projectId == null ? _selectedSmart : null,
                  selectedProjectId: _projectId,
                  onSelectSmart: _selectSmart,
                  onSelectProject: _selectProject,
                  onAddProject: _addProject,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _Header(
                    isWide: isWide,
                    title: _viewTitle(),
                    subtitle: _viewSubtitle(),
                    searchFocus: _searchFocus,
                    searchCtrl: _searchCtrl,
                    query: _query,
                    onQueryChanged: (q) => setState(() => _query = q),
                    onClearQuery: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                      _searchFocus.unfocus();
                    },
                    onOpenDrawer: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    showBack: !isWide && _projectId != null,
                    onBack: _clearProject,
                    onToggleTheme: _toggleTheme,
                    onMenu: _headerMenu,
                  ),
                  if (_bannerTask != null)
                    ReminderBanner(
                      task: _bannerTask!,
                      now: DateTime.now(),
                      onOpen: () {
                        final task = _bannerTask!;
                        state.markReminderFired(task.id);
                        setState(() => _bannerTask = null);
                        _openTask(task);
                      },
                      onDismiss: () {
                        state.markReminderFired(_bannerTask!.id);
                        setState(() => _bannerTask = null);
                      },
                    ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _query.trim().isEmpty &&
                !_isNonTaskView()
            ? FloatingActionButton(
                tooltip: 'New task (Ctrl+N)',
                onPressed: () => _newTask(),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: isWide ? null : _bottomBar(),
      ),
    );
  }

  bool _isNonTaskView() =>
      _selectedSmart == SmartList.stats ||
      _selectedSmart == SmartList.settings ||
      _selectedSmart == SmartList.projects;

  Widget _drawer() {
    return Drawer(
      width: 264,
      child: Sidebar(
        state: state,
        now: DateTime.now(),
        selectedSmart: _projectId == null ? _selectedSmart : null,
        selectedProjectId: _projectId,
        onSelectSmart: _selectSmart,
        onSelectProject: _selectProject,
        onAddProject: _addProject,
      ),
    );
  }

  Widget _bottomBar() {
    final scheme = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: _navBarIndex(),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            _selectSmart(SmartList.today);
          case 1:
            _selectSmart(SmartList.inbox);
          case 2:
            _selectSmart(SmartList.projects);
          case 3:
            _selectSmart(SmartList.settings);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.today_outlined),
          selectedIcon: Icon(Icons.today),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Inbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
    );
  }

  int _navBarIndex() {
    if (_projectId != null) return 2;
    switch (_selectedSmart) {
      case SmartList.today:
        return 0;
      case SmartList.inbox:
        return 1;
      case SmartList.projects:
        return 2;
      case SmartList.settings:
        return 3;
      default:
        return 0;
    }
  }

  String _viewTitle() {
    if (_projectId != null) {
      return state.projectById(_projectId!)?.name ?? 'Project';
    }
    switch (_selectedSmart) {
      case SmartList.inbox:
        return 'Inbox';
      case SmartList.today:
        return 'Today';
      case SmartList.upcoming:
        return 'Upcoming';
      case SmartList.overdue:
        return 'Overdue';
      case SmartList.completed:
        return 'Completed';
      case SmartList.all:
        return 'All tasks';
      case SmartList.projects:
        return 'Projects';
      case SmartList.stats:
        return 'Stats';
      case SmartList.settings:
        return 'Settings';
    }
  }

  String _viewSubtitle() {
    final now = DateTime.now();
    if (_projectId != null) {
      final open = state.openIn(_projectId!).length;
      return '$open open ${open == 1 ? 'task' : 'tasks'}';
    }
    switch (_selectedSmart) {
      case SmartList.inbox:
        return 'Tasks without a project';
      case SmartList.today:
        return '${fmtDate(now)} — ${state.tasksDueToday(now).length} due today';
      case SmartList.upcoming:
        return 'Next 14 days';
      case SmartList.overdue:
        return '${state.overdueCount(now)} overdue';
      case SmartList.completed:
        return '${state.completedCount} done in total';
      case SmartList.all:
        return 'Everything that is still open';
      case SmartList.projects:
        return '${state.projects.length} ${state.projects.length == 1 ? 'project' : 'projects'}';
      case SmartList.stats:
        return 'Your productivity at a glance';
      case SmartList.settings:
        return 'Theme, data and backups';
    }
  }

  Widget _buildBody() {
    final now = DateTime.now();
    if (!state.settings.welcomeSeen && state.tasks.isEmpty) {
      return WelcomeView(
        state: state,
        onAddTask: () => _newTask(),
      );
    }
    if (_query.trim().isNotEmpty) {
      return SearchView(
        state: state,
        query: _query,
        now: now,
        onOpenTask: _openTask,
      );
    }
    if (_projectId != null) {
      final project = state.projectById(_projectId!);
      if (project == null) {
        return const SizedBox.shrink();
      }
      return ProjectView(
        state: state,
        project: project,
        now: now,
        mode: _projectMode,
        onModeChanged: (mode) => setState(() => _projectMode = mode),
        onOpenTask: _openTask,
        onNewTask: (status) => _newTask(status: status),
        onEditProject: () => _editProject(project),
        onDeleteProject: () => _deleteProject(project),
      );
    }
    switch (_selectedSmart) {
      case SmartList.inbox:
        return TaskListView(
          state: state,
          tasks: state.openIn(''),
          now: now,
          emptyState: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Inbox is clear',
            message: 'Tasks that are not part of a project live here.',
            actionLabel: 'Add a task',
            onAction: () => _newTask(),
          ),
          onOpenTask: _openTask,
        );
      case SmartList.today:
        return TodayView(state: state, now: now, onOpenTask: _openTask);
      case SmartList.upcoming:
        return UpcomingView(state: state, now: now, onOpenTask: _openTask);
      case SmartList.overdue:
        return TaskListView(
          state: state,
          tasks: state.overdueTasks(now),
          now: now,
          showProject: true,
          emptyState: const EmptyState(
            icon: Icons.celebration_outlined,
            title: 'All caught up',
            message: 'No overdue tasks. Keep it that way!',
          ),
          onOpenTask: _openTask,
        );
      case SmartList.completed:
        return TaskListView(
          state: state,
          tasks: state.completedTasks,
          now: now,
          groupByDate: true,
          swipeReopen: true,
          showProject: true,
          dateTitle: (day, count) => smartDate(day, now),
          emptyState: EmptyState(
            icon: Icons.done_all_outlined,
            title: 'Nothing completed yet',
            message: 'Complete a task and it will be archived here.',
            actionLabel: 'Go to Today',
            onAction: () => _selectSmart(SmartList.today),
          ),
          onOpenTask: _openTask,
        );
      case SmartList.all:
        return TaskListView(
          state: state,
          tasks: state.openTasks,
          now: now,
          showProject: true,
          emptyState: EmptyState(
            icon: Icons.layers_outlined,
            title: 'Nothing to do',
            message: 'Every single task is done. Time for a new challenge!',
            actionLabel: 'Add a task',
            onAction: () => _newTask(),
          ),
          onOpenTask: _openTask,
        );
      case SmartList.projects:
        return ProjectsPage(
          state: state,
          onOpenProject: _selectProject,
          onAddProject: _addProject,
          onEditProject: _editProject,
          onDeleteProject: _deleteProject,
        );
      case SmartList.stats:
        return StatsView(state: state, now: now);
      case SmartList.settings:
        return SettingsView(state: state);
    }
  }

  void _toggleTheme() {
    state.settings.themeMode = (state.settings.themeMode + 1) % 3;
    state.notifySettingsChanged();
  }

  Future<void> _headerMenu(String action) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case 'new':
        await _newTask();
      case 'export':
        try {
          final message = await state.exportBackupNow();
          messenger.showSnackBar(SnackBar(
              content: Text(message), duration: const Duration(seconds: 4)));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('$e')));
        }
      case 'import':
        await _importFromMenu(messenger);
      case 'sample':
        state.loadSampleData();
        messenger.showSnackBar(const SnackBar(
            content: Text('Sample data loaded. Enjoy exploring!')));
      case 'about':
        await _showAbout();
    }
  }

  Future<void> _importFromMenu(ScaffoldMessengerState messenger) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
            'This replaces all current tasks and projects with the backup. '
            'You can undo afterwards.'),
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
            const SnackBar(content: Text('Import cancelled.')));
        return;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(summary),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Undo', onPressed: () => state.undo()),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showAbout() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TaskFlow'),
        content: const Text(
          'TaskFlow is an advanced, offline-first to-do list. '
          'Smart lists, projects, a Kanban board, subtasks, priorities, '
          'tags, repeating tasks, reminders, streaks and backups — all '
          'stored locally on your device.\n\n'
          'Keyboard: Ctrl+N new task · Ctrl+K search · Esc clear search.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isWide,
    required this.title,
    required this.subtitle,
    required this.searchFocus,
    required this.searchCtrl,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onOpenDrawer,
    required this.showBack,
    required this.onBack,
    required this.onToggleTheme,
    required this.onMenu,
  });

  final bool isWide;
  final String title;
  final String subtitle;
  final FocusNode searchFocus;
  final TextEditingController searchCtrl;
  final String query;
  final void Function(String) onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onOpenDrawer;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final void Function(String action) onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              tooltip: showBack ? 'Back' : 'Menu',
              onPressed: showBack ? onBack : onOpenDrawer,
              icon: Icon(
                  showBack ? Icons.arrow_back : Icons.menu,
                  size: 20),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: isWide ? 260 : 170,
            child: Shortcuts(
              shortcuts: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    const _ClearSearchIntent(),
              },
              child: Actions(
                actions: {
                  _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
                    onInvoke: (_) {
                      onClearQuery();
                      return null;
                    },
                  ),
                },
                child: TextField(
                  focusNode: searchFocus,
                  controller: searchCtrl,
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Search tasks…  (Ctrl+K)',
                    prefixIcon:
                        const Icon(Icons.search, size: 18),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: onClearQuery,
                          ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: onToggleTheme,
            icon: Icon(_themeIcon(context)),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
            onSelected: onMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'new',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New task (Ctrl+N)'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Export backup'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Import backup'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'sample',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_outlined),
                  title: Text('Load sample data'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(BuildContext context) {
    final mode = Theme.of(context).brightness;
    return mode == Brightness.dark
        ? Icons.dark_mode_outlined
        : Icons.light_mode_outlined;
  }
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

