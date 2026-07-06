import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'showfase_preview.dart';

/// Signature of a generated preview thunk.
///
/// Generated code emits closures such as `() => myPreviewFn()` or
/// `() => MyWidget.preview()`. The return type is either `Widget` or
/// `WidgetBuilder`; at this API boundary the static type is erased to
/// `Object?` so a single signature covers both, and the concrete runtime
/// closure type is inspected to dispatch (mirroring `flutter_tools`'
/// `buildWidgetPreview`).
typedef PreviewThunk = Object? Function();

/// Builds a single [ShowfasePreview] from a transformed [Preview] and its
/// thunk.
///
/// The generator calls this helper for annotations that are not
/// [MultiPreview]s. `transformedPreview` is the result of
/// `Preview.transform()`, allowing custom subclasses to inject runtime
/// setup.
ShowfasePreview buildShowfasePreview({
  required String id,
  required Preview transformedPreview,
  required PreviewThunk previewFunction,
  String? scriptUri,
  int? line,
  int? column,
}) {
  return ShowfasePreview(
    id: id,
    previewData: transformedPreview,
    scriptUri: scriptUri,
    line: line,
    column: column,
    builder: _thunkToBuilder(previewFunction),
  );
}

/// Expands a [MultiPreview] into a sequence of [ShowfasePreview]s.
///
/// `MultiPreview.transform()` is invoked at call time so subclasses that
/// override it are honored. Each expansion receives a distinct
/// `<baseId>#<i>` id.
Iterable<ShowfasePreview> buildShowfaseMultiPreview({
  required String id,
  required MultiPreview multiPreview,
  required PreviewThunk previewFunction,
  String? scriptUri,
  int? line,
  int? column,
}) sync* {
  final List<Preview> expanded = multiPreview.transform();
  final Widget Function() builder = _thunkToBuilder(previewFunction);
  for (int i = 0; i < expanded.length; i++) {
    yield ShowfasePreview(
      id: '$id#$i',
      previewData: expanded[i],
      scriptUri: scriptUri,
      line: line,
      column: column,
      builder: builder,
    );
  }
}

Widget Function() _thunkToBuilder(PreviewThunk thunk) {
  if (thunk is WidgetBuilder Function()) {
    return () => Builder(builder: thunk());
  }
  if (thunk is Widget Function()) {
    return thunk;
  }
  return () {
    final Object? value = thunk();
    if (value is Widget) return value;
    if (value is WidgetBuilder) return Builder(builder: value);
    throw ArgumentError(
      'previewFunction must return a Widget or WidgetBuilder, '
      'got ${value.runtimeType}',
    );
  };
}
