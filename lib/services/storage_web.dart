// ignore_for_file: deprecated_member_use
import 'dart:html' as html;

import 'storage.dart';

/// Browser storage backed by `localStorage`.
class WebStorage implements Storage {
  static const _key = 'taskflow.data.v1';

  @override
  Future<String?> load() async {
    try {
      return html.window.localStorage[_key];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String data) async {
    try {
      html.window.localStorage[_key] = data;
    } catch (_) {}
  }
}

Storage createStorage() => WebStorage();
