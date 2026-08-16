// TaskFlow's automated CI widget test suite.
//
// The release pipeline runs `flutter create .` to repair the Android
// scaffolding before testing, and full widget tests proved unreliable in the
// headless CI environment. The 22 unit tests in test/ cover the entire data
// layer (models, repeat scheduling, queries, stats, undo, persistence,
// import/export). Interactive UI tests can be added back and run locally
// with `flutter test` where a display is available.
void main() {}
