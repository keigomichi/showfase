# showfase

A Flutter UI catalog generated from `@Preview` annotations.

showfase is a Flutter port of Airbnb's
[Showkase](https://github.com/airbnb/Showkase). It reads Flutter's own
`@Preview` widgets — the ones normally displayed in the
[Widget Preview](https://docs.flutter.dev/tools/widget-previewer) tool — and
produces a **standalone Flutter app that runs on mobile, desktop, and web**.
It is intended for design-system showcases, QA hand-off, and design review.

## Layout

This repository is a pub workspace + melos monorepo:

| Package | Description |
| --- | --- |
| [`showfase_annotation`](packages/showfase_annotation) | Anchor annotation (`@ShowfaseRoot`). Pure Dart. |
| [`showfase_generator`](packages/showfase_generator) | `build_runner` code generator that collects `@Preview` widgets. |
| [`showfase`](packages/showfase) | Flutter runtime (`ShowfaseApp`, `ShowfaseBrowser`, preview detail screen). |
| [`showfase_test`](packages/showfase_test) | Golden (snapshot) testing — renders every preview offscreen for visual regression tests. |
| [`packages/showfase/example`](packages/showfase/example) | Demo app with committed generated file and golden tests. |

## Architecture

```
    +-----------------+       @Preview        +-----------------+
    |  Your widgets   |  --------------->  ── |  showfase       |
    |  (foo.dart)     |                       |  generator      |
    +-----------------+                       +--------+--------+
                                                       |
                                                       | build_runner
                                                       v
    +-----------------+                       +-----------------+
    | @ShowfaseRoot() |  <----- imports ----- |  showfase.g.dart|
    | void main() =>  |                       |  showfasePreviews()
    |   runApp(...)   |                       +-----------------+
    +--------+--------+
             |
             | flutter run -t lib/showfase.dart
             v
    +-----------------+
    | catalog app     |
    | (mobile/desktop |
    |  /web)          |
    +-----------------+
```

The generator runs in two phases (a standard `build_runner` aggregating
pattern):

1. **`preview_scanner`** — walks every `.dart` library in the target package,
   detects any element annotated with `@Preview` or a subclass of
   `MultiPreview`, encodes the annotation into a `.showfase.json` cache file.
2. **`showfase_builder`** — reacts to the single `@ShowfaseRoot()` declaration
   in the package, reads every `.showfase.json`, and emits one
   `<library>.g.dart` next to it.

Annotations are re-emitted as `const` expressions and `.transform()` is
invoked at runtime, so custom `Preview` / `MultiPreview` subclasses and their
`wrapper` / `theme` / `localizations` callbacks are supported natively.

## Quickstart

Add the packages to your app:

```yaml
# pubspec.yaml
dependencies:
  showfase: 0.1.0
  showfase_annotation: 0.1.0

dev_dependencies:
  build_runner: 2.15.0
  showfase_generator: 0.1.0
```

Create a catalog entry point (`lib/showfase.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

// Import each file that contains @Preview-annotated widgets so the code
// generator resolves them.
// ignore: unused_import
import 'widgets/buttons.dart';

import 'showfase.g.dart';

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
```

Add a preview somewhere:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Primary', group: 'Buttons')
Widget primaryButtonPreview() =>
    FilledButton(onPressed: () {}, child: const Text('Tap me'));
```

Run the generator and launch the catalog:

```bash
dart run build_runner build
flutter run -t lib/showfase.dart
```

## What annotations are supported?

Everything Flutter's Widget Preview tool supports:

* Top-level functions returning `Widget` or `WidgetBuilder`
* Static methods on classes
* Constructors and factories with no required parameters
* Stacked `@Preview()` annotations on the same function
* Custom `MultiPreview` subclasses
* All `Preview` fields: `group`, `name`, `size`, `textScaleFactor`, `wrapper`,
  `theme`, `brightness`, `localizations`

## Browser controls

The detail screen for each preview lets you toggle:

* Brightness (system / light / dark)
* Text scale (0.5×–3.0×)
* Right-to-left layout
* Locale (when the preview supplies `localizations`)

## Golden testing (Visual Regression Testing)

`showfase_test` turns the generated catalog into golden tests: one test per
preview × device, compared against committed PNG baselines with
`matchesGoldenFile`.

```yaml
# pubspec.yaml
dev_dependencies:
  showfase_test: 0.1.0
```

```dart
// test/showfase_test.dart
import 'package:flutter/material.dart';
import 'package:my_app/showfase.g.dart';
import 'package:showfase_test/showfase_test.dart';

Future<void> main() async {
  await testShowfase(
    showfasePreviews(),
    devices: [SnapshotDevice.iPhone15],
    builder: (preview, device) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: preview),
    ),
  );
}
```

Snapshots are written to `test/snapshots/<device>/<group>/<name>.png`. Two
ways to run it:

* **Record-only (what this repo does)**: always run with `--update-goldens`
  on a single OS (CI) and hand the PNGs to an external diff tool such as
  [reg-suit](https://github.com/reg-viz/reg-suit), or review them as CI
  artifacts. Rendering (text anti-aliasing) differs slightly across operating
  systems, so baselines and comparisons must come from the same OS.
* **Committed goldens**: record with `--update-goldens`, commit the PNGs, and
  let plain `flutter test` fail on any visual diff — viable when everyone
  records on the same OS as CI.

See [`packages/showfase_test`](packages/showfase_test) for devices, sizing
rules, and sharding.

## Multi-package projects

v1 aggregates only inside the package that hosts `@ShowfaseRoot`. To include
previews from other workspace packages, expose a `showfasePreviews()` from
each and combine them manually:

```dart
import 'package:my_app/showfase.g.dart' as app;
import 'package:my_ui_kit/showfase.g.dart' as uiKit;

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: <ShowfasePreview>[
      ...app.showfasePreviews(),
      ...uiKit.showfasePreviews(),
    ]));
```

## Compatibility

showfase tracks Flutter's `widget_previews` API. Requirements:

* Flutter ≥ 3.38 (for `MultiPreview`, `group`, and `Preview.transform()`)
* Dart ≥ 3.11

The `widget_previews` library is still marked experimental by Flutter and may
change without deprecation. showfase pins Flutter's upper bound conservatively
and issues a matching release each Flutter stable.

## Development

```bash
mise use               # activates pinned Flutter 3.41.6 + Dart 3.11.1
dart pub get
melos run analyze      # dart analyze everywhere
melos run test         # dart test everywhere
melos run test:flutter # flutter test for Flutter packages (excl. snapshots)
melos run snapshot     # take catalog snapshots (record-only, CI uploads them)
melos run build        # regenerate the example's showfase.g.dart
```

## License

Apache-2.0. See [LICENSE](LICENSE).
