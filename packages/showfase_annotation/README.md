# showfase_annotation

Annotations for [showfase](https://github.com/keigomichi/showfase) — a Flutter
UI catalog generator that consumes Flutter's `@Preview` widgets.

This is a **pure Dart** package with a single dependency (`meta`). The
runtime widgets live in the [`showfase`](../showfase) package; the code
generator lives in [`showfase_generator`](../showfase_generator).

## `ShowfaseRoot`

Apply `@ShowfaseRoot()` to the `main` function (or the top-level widget
class) of the file that hosts your catalog app. `showfase_generator` emits a
sibling `<library>.g.dart` containing `showfasePreviews()`:

```dart
// lib/showfase.dart
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

import 'showfase.g.dart';

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
```

Exactly one declaration in a package must carry this annotation; a build
error is raised otherwise.
