import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';

import 'font_builder.dart';
import 'snapshot_device.dart';
import 'snapshot_paths.dart';
import 'snapshot_shard.dart';
import 'snapshot_support.dart';

/// Wraps the rendered preview in the app shell used for snapshots.
///
/// [preview] is the fully layered preview canvas; wrap it in whatever your
/// app needs around a screen — typically a `MaterialApp` with your theme.
typedef SnapshotBuilder =
    Widget Function(Widget preview, SnapshotDevice device);

/// Registers one golden test per preview × device.
///
/// Tests are grouped as `device.name > preview.group > <file name>` and each
/// compares against
/// `<snapshotDir>[/<subDir>]/<device.name>/<group>/<name>.png`, resolved
/// relative to the calling test file. Run with `--update-goldens` to record.
///
/// [shard] registers only that slice of the previews, for parallel runs
/// across CI jobs and/or test files — see [SnapshotShard]. It applies after
/// [previewFilter], and golden paths (including collision suffixes) are
/// resolved from the full filtered list first, so a preview's path never
/// depends on the shard configuration.
///
/// ```dart
/// Future<void> main() async {
///   await testShowfase(
///     showfasePreviews(),
///     devices: [SnapshotDevice.iPhone15],
///     builder: (preview, device) => MaterialApp(
///       debugShowCheckedModeBanner: false,
///       home: Scaffold(body: preview),
///     ),
///   );
/// }
/// ```
Future<void> testShowfase(
  List<ShowfasePreview> previews, {
  required List<SnapshotDevice> devices,
  required SnapshotBuilder builder,
  String snapshotDir = 'snapshots',
  String? subDir,
  bool Function(ShowfasePreview preview)? previewFilter,
  SnapshotShard? shard,
  Map<String, List<String>> additionalFonts = const <String, List<String>>{},
  Future<void> Function(WidgetTester tester)? setUpEachTest,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await FontBuilder.loadFonts(additionalFonts: additionalFonts);

  final List<ShowfasePreview> filtered = previewFilter == null
      ? previews
      : previews.where(previewFilter).toList();

  final List<String> paths = resolveSnapshotPaths(
    filtered,
    onCollision: (String path, List<String> ids) {
      debugPrint(
        'showfase_test: multiple previews map to "$path.png" '
        '(${ids.join(', ')}). Suffixes were appended; add distinct '
        '@Preview(name:)s to disambiguate.',
      );
    },
  );

  final Map<String, List<int>> groups = <String, List<int>>{};
  for (int i = 0; i < filtered.length; i++) {
    (groups[filtered[i].group] ??= <int>[]).add(i);
  }

  final String sub = subDir != null ? '$subDir/' : '';
  for (final SnapshotDevice device in devices) {
    group(device.name, () {
      for (final MapEntry<String, List<int>> entry in groups.entries) {
        group(entry.key, () {
          for (final int i in entry.value) {
            // Skipped previews still contributed to path resolution above, so
            // collision suffixes are identical in every shard configuration.
            if (shard != null && !shard.contains(i)) continue;
            final ShowfasePreview preview = filtered[i];
            final String goldenPath =
                '$snapshotDir/$sub${device.name}/${paths[i]}.png';
            // The deduplicated file base name is unique within the group,
            // unlike the raw display name.
            testWidgets(paths[i].split('/').last, (WidgetTester tester) async {
              await _takeSnapshot(
                tester: tester,
                preview: preview,
                device: device,
                builder: builder,
                goldenPath: goldenPath,
                setUpEachTest: setUpEachTest,
              );
            });
          }
        });
      }
    });
  }
}

Future<void> _takeSnapshot({
  required WidgetTester tester,
  required ShowfasePreview preview,
  required SnapshotDevice device,
  required SnapshotBuilder builder,
  required String goldenPath,
  required Future<void> Function(WidgetTester tester)? setUpEachTest,
}) async {
  // The binding verifies foundation debug variables right after the test
  // body — before tearDown callbacks run — so the platform override must be
  // restored in a `finally`, not via addTearDown.
  debugDefaultTargetPlatformOverride = device.platform;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final Widget target = Builder(
    builder: (BuildContext context) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: device.safeAreaInsets,
          viewPadding: device.safeAreaInsets,
          devicePixelRatio: device.pixelRatio,
          textScaler: device.textScaler,
          platformBrightness: device.brightness,
        ),
        // Safety net for builders that don't set up a Directionality; any
        // WidgetsApp-based shell overrides it.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: builder(ShowfasePreviewCanvas(preview: preview), device),
        ),
      );
    },
  );

  try {
    // Pumping and resizing run under fake async, which is faster; only image
    // decoding (inside precacheAssetImage) and user setup get real async.
    await SnapshotSupport.startDevice(target, tester, device, preview);
    await SnapshotSupport.resize(preview, tester, device);
    await SnapshotSupport.precacheAssetImage(tester);
    if (setUpEachTest != null) {
      await tester.runAsync(() => setUpEachTest(tester));
    }
    await expectLater(find.byWidget(target), matchesGoldenFile(goldenPath));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
