/// Backup export/import, with per-platform implementations chosen at
/// compile time (download/upload on web, files/clipboard elsewhere).
import 'backup_io.dart' if (dart.library.html) 'backup_web.dart' as impl;

/// Exports [json] and returns a user-facing message describing where it went.
Future<String> exportBackup(String json, {required DateTime now}) =>
    impl.exportBackup(json, now: now);

/// Lets the user pick a backup to import. Returns its raw JSON, or null when
/// the user cancels. Throws [Exception] with a readable message on failure.
Future<String?> pickImportFile() => impl.pickImportFile();
