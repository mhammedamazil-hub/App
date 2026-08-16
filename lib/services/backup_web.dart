// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../utils/dates.dart';

Future<String> exportBackup(String json, {required DateTime now}) async {
  final name = 'taskflow-backup-${fileStamp(now)}.json';
  final bytes = utf8.encode(json);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = name;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Backup downloaded as $name';
}

Future<String?> pickImportFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'application/json,.json';
  input.click();
  final completer = Completer<String?>();
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) {
      completer.completeError(Exception('Could not read the selected file.'));
    });
    reader.readAsText(files.first);
  });
  return completer.future;
}
