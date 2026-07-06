# showfase_example

Demo app for [showfase](../../../README.md).

Its previews cover every supported shape:

| File | Demonstrates |
| --- | --- |
| `lib/widgets/buttons.dart` | top-level function, `WidgetBuilder` return, static method, constructor, factory |
| `lib/widgets/cards.dart` | `size`, `textScaleFactor`, `brightness` |
| `lib/widgets/scoped.dart` | static `wrapper` |
| `lib/widgets/brightness_preview.dart` | custom `MultiPreview` subclass, stacked `@Preview()` |

The entry point `lib/showfase.dart` is annotated `@ShowfaseRoot()`; the
committed `lib/showfase.g.dart` is the generator's output.

## Running

```bash
dart run build_runner build
flutter run -t lib/showfase.dart   # or `flutter build web --release`
```

## Regenerating

```bash
dart run build_runner build
```

The generated file is deterministic (sorted by library URI + function name);
CI can gate on `git diff --exit-code lib/showfase.g.dart` after running the
build.
