import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_test/showfase_test.dart';
import 'package:showfase_test/src/snapshot_support.dart';

// A small device keeps the committed golden PNGs tiny. Everything below
// renders with the deterministic FlutterTest font, so these goldens are
// stable across platforms and stay untagged.
const _device = SnapshotDevice(
  name: 'testDevice',
  size: Size(200, 300),
  platform: TargetPlatform.android,
);

Widget _redBox() => const ColoredBox(color: Color(0xFFCC3333));

Widget _label() => const Text(
  'Showfase',
  style: TextStyle(fontSize: 20, color: Color(0xFF222222)),
);

Widget _list() => ListView(
  children: [
    for (var i = 0; i < 30; i++)
      SizedBox(
        height: 40,
        child: ColoredBox(
          color: i.isEven ? const Color(0xFFEEEEEE) : const Color(0xFF99BBDD),
        ),
      ),
  ],
);

Widget _brightnessProbe() => Builder(
  builder: (context) => ColoredBox(
    color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? const Color(0xFF222244)
        : const Color(0xFFFFFFEE),
  ),
);

Widget _wrap(Widget child) => Padding(
  padding: const EdgeInsets.all(20),
  child: ColoredBox(color: const Color(0xFF33CC66), child: child),
);

const _previews = <ShowfasePreview>[
  ShowfasePreview(
    id: 't#fixedBox',
    previewData: Preview(name: 'Fixed', group: 'Boxes', size: Size(100, 50)),
    builder: _redBox,
  ),
  ShowfasePreview(
    id: 't#label',
    previewData: Preview(name: 'Label', group: 'Text'),
    builder: _label,
  ),
  ShowfasePreview(
    id: 't#list',
    previewData: Preview(name: 'List', group: 'Lists'),
    builder: _list,
  ),
  ShowfasePreview(
    id: 't#wrapped',
    previewData: Preview(name: 'Wrapped', group: 'Boxes', wrapper: _wrap),
    builder: _redBox,
  ),
  ShowfasePreview(
    id: 't#brightness',
    previewData: Preview(name: 'Brightness', group: 'Boxes'),
    builder: _brightnessProbe,
  ),
];

Widget _shell(Widget preview, SnapshotDevice device) =>
    ColoredBox(color: const Color(0xFFFFFFFF), child: preview);

Future<void> main() async {
  await testShowfase(
    _previews,
    devices: [
      _device,
      _device.copyWith(name: 'testDevice-dark', brightness: Brightness.dark),
    ],
    builder: _shell,
    snapshotDir: 'goldens',
  );

  // previewFilter narrows the run; subDir redirects the output.
  await testShowfase(
    _previews,
    devices: const [_device],
    builder: _shell,
    snapshotDir: 'goldens',
    subDir: 'filtered',
    previewFilter: (preview) => preview.name == 'Fixed',
  );

  testWidgets('resize grows the surface to fit scrollable content', (
    tester,
  ) async {
    const preview = ShowfasePreview(
      id: 't#list',
      previewData: Preview(),
      builder: _list,
    );
    await SnapshotSupport.startDevice(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShowfasePreviewCanvas(preview: preview),
      ),
      tester,
      _device,
    );
    await SnapshotSupport.resize(preview, tester, _device);
    // 30 items × 40px: maxScrollExtent (900) + viewport (300).
    expect(tester.view.physicalSize, const Size(200, 1200));
    addTearDown(tester.view.reset);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('resize keeps a fixed axis while growing the other', (
    tester,
  ) async {
    const preview = ShowfasePreview(
      id: 't#list',
      previewData: Preview(size: Size(120, double.infinity)),
      builder: _list,
    );
    await SnapshotSupport.startDevice(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShowfasePreviewCanvas(preview: preview),
      ),
      tester,
      _device,
    );
    await SnapshotSupport.resize(preview, tester, _device);
    expect(tester.view.physicalSize.width, 120);
    expect(tester.view.physicalSize.height, greaterThan(300));
    addTearDown(tester.view.reset);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('resize rejects content larger than the size limit', (
    tester,
  ) async {
    const preview = ShowfasePreview(
      id: 't#huge',
      previewData: Preview(),
      builder: _hugeList,
    );
    await SnapshotSupport.startDevice(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShowfasePreviewCanvas(preview: preview),
      ),
      tester,
      _device,
    );
    await expectLater(
      () => SnapshotSupport.resize(preview, tester, _device),
      throwsStateError,
    );
    addTearDown(tester.view.reset);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

Widget _hugeList() => ListView(
  children: [for (var i = 0; i < 200; i++) const SizedBox(height: 400)],
);
