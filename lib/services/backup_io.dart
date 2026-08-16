import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/dates.dart';

const MethodChannel _channel = MethodChannel('taskflow.app/platform');

String _stamp(DateTime now) => fileStamp(now);

Future<String> exportBackup(String json, {required DateTime now}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await _channel.invokeMethod<void>('copyToClipboard', {'text': json});
      return 'Backup copied to the clipboard — paste it somewhere safe.';
    } catch (_) {
      // Fall through to file export.
    }
  }
  final env = Platform.environment;
  final home = env['HOME'] ?? Directory.current.path;
  final downloads = '$home/Downloads';
  final dir = Directory(downloads).existsSync()
      ? Directory(downloads)
      : Directory(home);
  final name = 'taskflow-backup-${_stamp(now)}.json';
  final file = File('${dir.path}/$name');
  await file.writeAsString(json, flush: true);
  return 'Backup saved to ${file.path}';
}

Future<String?> pickImportFile() async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final text = await _channel.invokeMethod<String>('getClipboard');
      if (text != null && text.trim().isNotEmpty) return text;
      throw Exception(
          'The clipboard has no TaskFlow backup. Copy one there first.');
    } catch (e) {
      rethrow;
    }
  }
  final env = Platform.environment;
  final home = env['HOME'] ?? Directory.current.path;
  final candidates = [
    '$home/Downloads/taskflow-import.json',
    '$home/taskflow-import.json',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsString();
    }
  }
  throw Exception(
      'No import file found. Place your backup at ${candidates.first} and try again.');
}
