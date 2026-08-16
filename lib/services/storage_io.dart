import 'dart:io';

import 'package:flutter/services.dart';

import 'storage.dart';

const MethodChannel _channel = MethodChannel('taskflow.app/platform');

/// Resolves a persistent, app-private data directory.
Future<Directory> _dataDir() async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final dir = await _channel.invokeMethod<String>('getDocumentsDirectory');
      if (dir != null && dir.isNotEmpty) {
        return Directory(dir);
      }
    } catch (_) {
      // Fall through to environment-based resolution.
    }
  }
  final env = Platform.environment;
  final home = env['HOME'] ?? Directory.current.path;
  if (Platform.isLinux) {
    return Directory('${env['XDG_DATA_HOME'] ?? '$home/.local/share'}/taskflow');
  }
  if (Platform.isMacOS) {
    return Directory('$home/Library/Application Support/taskflow');
  }
  if (Platform.isWindows) {
    return Directory('${env['APPDATA'] ?? home}/taskflow');
  }
  return Directory('$home/.taskflow');
}

Future<File> _dataFile() async => File('${(await _dataDir()).path}/taskflow_data.json');

class IoStorage implements Storage {
  IoStorage();

  File? _file;

  Future<File> _resolve() async {
    final existing = _file;
    if (existing != null) return existing;
    final resolved = await _dataFile();
    _file = resolved;
    return resolved;
  }

  @override
  Future<String?> load() async {
    try {
      final file = await _resolve();
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> save(String data) async {
    final file = await _resolve();
    await file.parent.create(recursive: true);
    // Atomic-ish write: write a temp file, then rename over the target.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }
}

Storage createStorage() => IoStorage();
