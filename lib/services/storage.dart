/// Storage abstraction for persisting the app's JSON document.
///
/// The implementation is chosen at compile time:
///  * `storage_io.dart`  — files (Android, iOS, desktop)
///  * `storage_web.dart` — browser localStorage
import 'storage_io.dart' if (dart.library.html) 'storage_web.dart' as impl;

abstract class Storage {
  Future<String?> load();
  Future<void> save(String data);
}

Storage createStorage() => impl.createStorage();
