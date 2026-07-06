// The catalog app's entry point lives in `showfase.dart` (annotated with
// `@ShowfaseRoot()`). Running `flutter run -t lib/showfase.dart` starts the
// catalog. This file re-exposes it so the plain `flutter run` also works.
export 'showfase.dart' show main;
