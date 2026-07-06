/// Test-only fakes for Flutter and Showfase runtime types, small enough that
/// the analyzer inside `testBuilders` can resolve user annotations without
/// pulling in the real Flutter SDK.
library;

const String fakeFlutterWidgets = '''
class Widget {
  const Widget();
}

typedef WidgetBuilder = Widget Function(dynamic context);
''';

const String fakeFlutterUi = '''
enum Brightness { light, dark }

class Size {
  const Size(this.width, this.height);
  const Size.fromHeight(double height) : width = double.infinity, height = height;
  const Size.fromWidth(double width) : width = width, height = double.infinity;
  final double width;
  final double height;
}
''';

const String fakeFlutterWidgetPreviews = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/src/ui.dart';

typedef WidgetWrapper = Widget Function(Widget);

base class Preview {
  const Preview({
    this.group = 'Default',
    this.name,
    this.size,
    this.textScaleFactor,
    this.wrapper,
    this.brightness,
  });
  final String group;
  final String? name;
  final Size? size;
  final double? textScaleFactor;
  final WidgetWrapper? wrapper;
  final Brightness? brightness;
  Preview transform() => this;
}

abstract base class MultiPreview {
  const MultiPreview();
  List<Preview> get previews;
  List<Preview> transform() => previews;
}
''';

const String fakeShowfaseAnnotation = '''
class ShowfaseRoot {
  const ShowfaseRoot();
}
''';

const String fakeShowfaseRuntime = r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

export 'package:flutter/widget_previews.dart' show Preview, MultiPreview;

class ShowfasePreview {
  const ShowfasePreview({
    required this.id,
    required this.builder,
    required this.previewData,
    this.scriptUri,
    this.line,
    this.column,
  });
  final String id;
  final Widget Function() builder;
  final Preview previewData;
  final String? scriptUri;
  final int? line;
  final int? column;
}

typedef PreviewThunk = Object? Function();

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
    builder: () => previewFunction() as Widget,
  );
}

Iterable<ShowfasePreview> buildShowfaseMultiPreview({
  required String id,
  required MultiPreview multiPreview,
  required PreviewThunk previewFunction,
  String? scriptUri,
  int? line,
  int? column,
}) sync* {
  for (final p in multiPreview.transform()) {
    yield ShowfasePreview(
      id: id,
      previewData: p,
      builder: () => previewFunction() as Widget,
    );
  }
}
''';

/// Common asset bundle for all end-to-end builder tests.
Map<String, Object> buildTestAssets(Map<String, Object> extras) => <String, Object>{
      'flutter|lib/widgets.dart': fakeFlutterWidgets,
      'flutter|lib/src/ui.dart': fakeFlutterUi,
      'flutter|lib/widget_previews.dart': fakeFlutterWidgetPreviews,
      'showfase_annotation|lib/showfase_annotation.dart': fakeShowfaseAnnotation,
      'showfase|lib/showfase.dart': fakeShowfaseRuntime,
      ...extras,
    };
