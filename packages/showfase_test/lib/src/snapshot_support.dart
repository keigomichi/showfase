import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';

import 'snapshot_device.dart';

/// Per-axis sizing derived from `Preview.size`: a finite dimension pins the
/// surface to that value; `null` / `double.infinity` means the axis is
/// "compressed" — it starts at the device size and grows to fit scrollable
/// content.
class _AxisSpec {
  const _AxisSpec({this.fixedWidth, this.fixedHeight});

  factory _AxisSpec.of(ShowfasePreview preview) {
    final Size? size = preview.previewData.size;
    return _AxisSpec(
      fixedWidth: size != null && size.width.isFinite ? size.width : null,
      fixedHeight: size != null && size.height.isFinite ? size.height : null,
    );
  }

  final double? fixedWidth;
  final double? fixedHeight;

  bool get resizesWidth => fixedWidth == null;
  bool get resizesHeight => fixedHeight == null;
}

/// Surface sizing and content-driven resizing for snapshot rendering.
class SnapshotSupport {
  const SnapshotSupport._();

  static const int _maxTryResizeCount = 10;
  static const double _maxSnapshotSize = 50000;

  /// Configures the render surface for [device] and pumps [target].
  static Future<void> startDevice(
    Widget target,
    WidgetTester tester,
    SnapshotDevice device,
  ) async {
    tester.view.devicePixelRatio = device.pixelRatio;
    await setSnapshotSize(tester, device.size, device.pixelRatio);
    await tester.pumpWidget(target);
    await tester.pumpAndSettle();
  }

  /// Adjusts the surface to [preview]'s `Preview.size`, growing compressed
  /// axes to fit scrollable content.
  ///
  /// Scrollables report `maxScrollExtent` against the current viewport, and
  /// the value may stabilize only after the surface grows, so the size is
  /// recomputed until it stops increasing (bounded by [_maxTryResizeCount]
  /// and [_maxSnapshotSize]).
  static Future<void> resize(
    ShowfasePreview preview,
    WidgetTester tester,
    SnapshotDevice device,
  ) async {
    final _AxisSpec spec = _AxisSpec.of(preview);

    if (!spec.resizesWidth && !spec.resizesHeight) {
      await setSnapshotSize(
        tester,
        Size(spec.fixedWidth!, spec.fixedHeight!),
        device.pixelRatio,
      );
      return;
    }

    Size lastExtendedSize = Size(
      spec.fixedWidth ?? device.size.width,
      spec.fixedHeight ?? device.size.height,
    );
    await setSnapshotSize(tester, lastExtendedSize, device.pixelRatio);

    int resizeCount = 0;
    while (true) {
      final Iterable<Widget> scrollables = find
          .byType(Scrollable)
          .evaluate()
          .map((Element e) => e.widget);
      if (scrollables.isEmpty) break;

      // A Scrollable may or may not own a ScrollController, so the
      // ScrollPosition is obtained from a ScrollableState found in the
      // innermost descendant instead.
      final Iterable<ScrollableState?> scrollableStates = scrollables
          .map(
            (Widget scrollable) => find
                .descendant(
                  of: find.byWidget(scrollable),
                  matching: find.byWidgetPredicate((Widget widget) => true),
                )
                .last
                .evaluate()
                .map(Scrollable.maybeOf)
                .firstWhere(
                  (ScrollableState? state) => state != null,
                  orElse: () => null,
                ),
          )
          .where((ScrollableState? state) => state != null);

      Size extendedSize = device.size;
      for (final ScrollableState? state in scrollableStates) {
        extendedSize = _extendScrollableSnapshotSize(
          scrollableState: state!,
          currentExtendedSize: extendedSize,
          originSize: lastExtendedSize,
          spec: spec,
        );
      }
      if (extendedSize <= lastExtendedSize) break;
      lastExtendedSize = extendedSize;
      await setSnapshotSize(tester, lastExtendedSize, device.pixelRatio);
      resizeCount++;
      if (resizeCount >= _maxTryResizeCount) {
        throw StateError(
          'Tried resizing too many times. '
          'Give the preview a fixed size via @Preview(size: ...).',
        );
      }
      if (extendedSize.width >= _maxSnapshotSize ||
          extendedSize.height >= _maxSnapshotSize) {
        throw StateError(
          'Tried resizing to too large a size $extendedSize. '
          'Give the preview a fixed size via @Preview(size: ...).',
        );
      }
    }
    await setSnapshotSize(tester, lastExtendedSize, device.pixelRatio);
  }

  /// Decodes every `Image` in the tree before capture.
  ///
  /// See https://github.com/flutter/flutter/issues/38997.
  static Future<void> precacheAssetImage(WidgetTester tester) async {
    for (final Element element in find.byType(Image).evaluate()) {
      final Image widget = element.widget as Image;
      await precacheImage(widget.image, element);
      await tester.pumpAndSettle();
    }
  }

  /// Sets the logical surface size and the matching physical size.
  static Future<void> setSnapshotSize(
    WidgetTester tester,
    Size size,
    double pixelRatio,
  ) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * pixelRatio;
    await tester.pumpAndSettle();
  }

  static Size _extendScrollableSnapshotSize({
    required ScrollableState scrollableState,
    required Size currentExtendedSize,
    required Size originSize,
    required _AxisSpec spec,
  }) {
    ScrollPosition? position;
    try {
      position = scrollableState.position;
    } on Object {
      position = null;
    }
    if (position == null) {
      return Size(
        spec.resizesWidth
            ? max(currentExtendedSize.width, originSize.width)
            : originSize.width,
        spec.resizesHeight
            ? max(currentExtendedSize.height, originSize.height)
            : originSize.height,
      );
    }

    final Size newExtendedSize = switch (position.axis) {
      Axis.horizontal => Size(
        max(
          position.maxScrollExtent + originSize.width,
          currentExtendedSize.width,
        ),
        max(originSize.height, currentExtendedSize.height),
      ),
      Axis.vertical => Size(
        max(originSize.width, currentExtendedSize.width),
        max(
          position.maxScrollExtent + originSize.height,
          currentExtendedSize.height,
        ),
      ),
    };
    return Size(
      spec.resizesWidth ? newExtendedSize.width : originSize.width,
      spec.resizesHeight ? newExtendedSize.height : originSize.height,
    );
  }
}
