# showfase_test

Golden (snapshot) testing for [showfase](../..) catalogs — renders every
`@Preview` offscreen and compares it against committed golden images, giving
you Visual Regression Tests from the catalog you already have.

## Quickstart

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

```bash
flutter test --update-goldens   # record snapshots
flutter test                    # compare against recorded PNGs
```

> **Cross-OS caveat**: glyph anti-aliasing differs slightly between macOS,
> Linux, and Windows, so snapshots containing text only compare cleanly on
> the OS they were recorded on. Either commit goldens recorded on the same
> OS your CI uses, or run record-only and diff externally (see below).

`testShowfase` registers **one test per preview × device**, grouped as
`<device> > <group> > <name>`, so failures are isolated and standard filtering
works:

```bash
flutter test --plain-name 'iPhone15 Buttons'
```

## Output layout

Snapshots are written relative to the test file:

```
test/snapshots/<device.name>/<group>/<name>.png
```

`<name>` is the preview's `name:`, falling back to the annotated function's
name. Colliding names (e.g. stacked `@Preview`s without distinct names) get
deterministic `_2`, `_3`, … suffixes and a warning.

## Sizing

The render surface is derived from `@Preview(size: ...)` per axis:

| Axis value | Behavior |
| --- | --- |
| finite (e.g. `280`) | Surface is fixed to that value. |
| `null` / `double.infinity` | Starts at the device size and grows to fit scrollable content. |

Unbounded content that would exceed 50,000 px throws a `StateError` asking
for a fixed `size`.

## Devices

Presets: `SnapshotDevice.iPhoneSE2nd`, `.iPhone15`, `.pixel6`. Each carries
size, safe-area insets, platform, and can be customized:

```dart
devices: [
  SnapshotDevice.iPhone15,
  SnapshotDevice.iPhone15.copyWith(
    name: 'iPhone15-dark',
    brightness: Brightness.dark,
  ),
  SnapshotDevice.pixel6.copyWith(
    orientation: SnapshotDeviceOrientation.landscape,
  ),
],
```

`brightness` feeds `MediaQuery.platformBrightness`; a preview's own
`@Preview(brightness: ...)` still wins, matching the catalog browser.

## Fonts

All font families declared in the app's `FontManifest.json` are loaded
automatically, so bundled fonts render as real glyphs. Everything else uses
flutter_test's deterministic `FlutterTest` font. Extra font files can be
loaded from disk:

```dart
additionalFonts: {
  'Roboto': ['assets/fonts/Roboto-Regular.ttf'],
},
```

Font *metrics* are deterministic, but glyph rasterization is not bit-exact
across operating systems — even with the default FlutterTest font. Keep
recording and comparison on the same OS.

## Sharding and parallelism

`shard:` registers only a 1-of-N slice of the previews (round-robin over the
deterministic preview order). Golden paths — including collision suffixes —
are resolved from the full list before slicing, so **every shard layout
produces the same file paths as an unsharded run**: all shards can share one
`snapshotDir`, and an external diff tool sees a stable baseline.

Because each preview is its own `testWidgets` and `flutter test` runs test
*files* concurrently, sharding parallelizes on two independent axes:

**Within one machine** — put one shard per file and run the directory; all
CPU cores are used by a single `flutter test` invocation:

```dart
// test/vrt/shard0_test.dart  (…repeat for shard1..shard3 with index: k)
Future<void> main() async {
  await testShowfase(
    showfasePreviews(),
    devices: [SnapshotDevice.iPhone15],
    shard: const SnapshotShard(index: 0, total: 4),
    builder: ...,
  );
}
```

```bash
flutter test --update-goldens test/vrt/
```

**Across CI jobs** — select the shard from `SHARD_INDEX` / `TOTAL_SHARDS`
(environment variables or `--dart-define`); unset means "run everything", so
the same file works locally:

```dart
shard: SnapshotShard.fromEnvironment(),
```

Both compose: for J jobs × K files per job, give file `k` of job `j`
`SnapshotShard(index: j * K + k, total: J * K)` (read `j` from the
environment). Ad-hoc subset runs are still available via `previewFilter`,
which applies before `shard`.

## Record-only mode + external diff tool (reg-suit etc.)

`--update-goldens` never compares — it only writes PNGs — so you can skip
committing goldens entirely and let a tool like
[reg-suit](https://github.com/reg-viz/reg-suit) manage baselines (this is how
playbook-flutter's own CI operates, and what this repository does — see the
`snapshot` melos script and the `Take snapshots` CI step):

```bash
rm -rf test/snapshots          # drop snapshots of deleted previews
flutter test --update-goldens  # capture
# hand test/snapshots/ to reg-suit for comparison & PR report,
# or upload as a CI artifact for manual review
```

Running always on one OS (CI) keeps both sides of the diff pixel-compatible.

## API

```dart
Future<void> testShowfase(
  List<ShowfasePreview> previews, {
  required List<SnapshotDevice> devices,
  required SnapshotBuilder builder,        // wrap the canvas in your app shell
  String snapshotDir = 'snapshots',
  String? subDir,
  bool Function(ShowfasePreview)? previewFilter,
  SnapshotShard? shard,                    // 1-of-N slice for parallel runs
  Map<String, List<String>> additionalFonts,
  Future<void> Function(WidgetTester)? setUpEachTest,
});
```

`builder` receives the fully layered preview (wrapper, theme, brightness,
localizations, text scale, and size from the `@Preview` annotation are already
applied) — wrap it in whatever your widgets need, typically a `MaterialApp`
with your app theme.

## License

Apache-2.0. See [LICENSE](LICENSE).
