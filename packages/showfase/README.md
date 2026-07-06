# showfase

Runtime for [showfase](https://github.com/keigomichi/showfase) — a Flutter UI
catalog generated from `@Preview` annotations.

The generator lives in [`showfase_generator`](../showfase_generator); the
anchor annotation lives in
[`showfase_annotation`](../showfase_annotation).

## Usage

Import `package:showfase/showfase.dart` and pass the generated
`showfasePreviews()` output to `ShowfaseApp`:

```dart
import 'package:flutter/widgets.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

import 'showfase.g.dart';

@ShowfaseRoot()
void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
```

To embed the catalog inside an existing app, use `ShowfaseBrowser` directly
(it doesn't wrap itself in a `MaterialApp`):

```dart
Scaffold(body: ShowfaseBrowser(previews: showfasePreviews()));
```

## What you get

* **Group view** — previews grouped by their `Preview.group`.
* **Search** — filter by name or group.
* **Detail screen** — the preview rendered with runtime controls for:
  * brightness (system / light / dark),
  * text scale (0.5×–3.0×),
  * right-to-left layout,
  * plus any `wrapper` / `theme` / `localizations` the annotation specified.

The `ShowfasePreviewCanvas` widget applies all of a `Preview`'s environment
overrides — you can use it standalone to render a single preview elsewhere.

## Requirements

* Flutter ≥ 3.38 (for the current `Preview` API shape: `group`, `MultiPreview`,
  `Preview.transform()`).
* Dart ≥ 3.11.

The `widget_previews` library is still marked experimental by Flutter. This
package pins Flutter's upper bound conservatively and issues a matching
release each Flutter stable.
