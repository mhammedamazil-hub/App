import 'package:flutter/material.dart';

/// Accent seed colors offered in Settings.
const List<Color> accentSeeds = [
  Color(0xFF4C6EF5), // indigo
  Color(0xFF0CA678), // green
  Color(0xFFF76707), // orange
  Color(0xFFE64980), // pink
  Color(0xFF7048E8), // violet
  Color(0xFF1098AD), // cyan
  Color(0xFFF03E3E), // red
  Color(0xFF7950F2), // grape
];

/// Palette for project colors.
const List<Color> projectColors = [
  Color(0xFF4C6EF5),
  Color(0xFF0CA678),
  Color(0xFFF76707),
  Color(0xFFE64980),
  Color(0xFF7048E8),
  Color(0xFF1098AD),
  Color(0xFFF03E3E),
  Color(0xFF2F9E44),
  Color(0xFFF59F00),
  Color(0xFFA61E4D),
  Color(0xFF364FC7),
  Color(0xFF087F5B),
];

const List<IconData> projectIcons = [
  Icons.folder_outlined,
  Icons.work_outline,
  Icons.home_outlined,
  Icons.fitness_center,
  Icons.school_outlined,
  Icons.shopping_bag_outlined,
  Icons.flight_takeoff,
  Icons.favorite_outline,
  Icons.lightbulb_outline,
  Icons.book_outlined,
  Icons.music_note_outlined,
  Icons.savings_outlined,
];

Color projectColor(int index) => projectColors[index % projectColors.length];

IconData projectIcon(int index) => projectIcons[index % projectIcons.length];

/// Priority accent colors (index by `TaskPriority.index`).
Color? priorityColor(BuildContext context, int priorityIndex) {
  final scheme = Theme.of(context).colorScheme;
  switch (priorityIndex) {
    case 1:
      return const Color(0xFF339AF0);
    case 2:
      return const Color(0xFFF59F00);
    case 3:
      return scheme.error;
    default:
      return null;
  }
}

ThemeData buildTheme({required Color seed, required Brightness brightness}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outlineVariant,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
