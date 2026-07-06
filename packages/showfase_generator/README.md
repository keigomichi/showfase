# showfase_generator

`build_runner` code generator for [showfase](https://github.com/keigomichi/showfase).

Discovers Flutter `@Preview`- and `MultiPreview`-annotated widgets across your
package and emits a single Dart file that exports a
`List<ShowfasePreview> showfasePreviews()` function ready to hand to
`ShowfaseApp`.

## Setup

Add dev dependencies:

```yaml
dev_dependencies:
  build_runner: 2.15.0
  showfase_generator: 0.1.0
```

Anchor the generated file by annotating one declaration with `@ShowfaseRoot()`
(from [`showfase_annotation`](../showfase_annotation)):

```dart
// lib/showfase.dart
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

import 'showfase.g.dart';   // generated

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
```

Run:

```bash
dart run build_runner build
```

## Configuration

You can restrict which files are scanned via `build.yaml`:

```yaml
# your app's build.yaml
targets:
  $default:
    builders:
      showfase_generator:preview_scanner:
        generate_for:
          include:
            - lib/**
          exclude:
            - lib/**.g.dart
```

## How it works

Two-phase aggregating builder (same pattern as `widgetbook_generator` and
`auto_route_generator`):

1. **`preview_scanner`** — one pass per library. Detects any element
   annotated with a subtype of `Preview` or `MultiPreview` from
   `package:flutter/widget_previews.dart`, validates it (public, no required
   parameters, returns `Widget` or `WidgetBuilder`), encodes the annotation
   value into a JSON constant tree, and writes it to a cache file with
   extension `.showfase.json`.
2. **`showfase_builder`** — reacts to the one declaration annotated with
   `@ShowfaseRoot()`. Reads every `.showfase.json` in the package, sorts by
   library URI + function name for stable output, and emits one Dart file
   next to the anchor.

Annotations are reconstructed as `const` expressions (with prefixed imports
for every source library) and `.transform()` is called at runtime — so
custom `Preview` subclasses, `MultiPreview` subclasses, and their static
`wrapper` / `theme` / `localizations` callbacks all work.

The generator itself has **no Flutter dependency** (it runs in `dart run
build_runner` on the pure Dart VM). It analyzes Flutter code through the
`analyzer` package.

## Multi-package projects

v1 aggregates only inside the package that hosts `@ShowfaseRoot`. To include
previews from workspace-sibling packages, expose a `showfasePreviews()` from
each and combine them manually — see the top-level [README](../../README.md).
