import 'dart:math';

final Random _rand = Random();

/// Generates a short, sortable, reasonably-unique id.
String uid() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _rand.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
  return '${time}_$rand';
}
