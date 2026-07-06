import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:showfase_generator/builder.dart';
import 'package:test/test.dart';

import 'fakes.dart';

/// Runs the two-phase pipeline and captures the generated `showfase.g.dart`
/// (if any) as a `String`, plus any severe log records.
Future<_RunResult> _run(Map<String, Object> extraAssets) async {
  final List<LogRecord> logs = <LogRecord>[];
  final Builder scanner = previewScannerBuilder(BuilderOptions.empty);
  final Builder aggregator = showfaseBuilder(BuilderOptions.empty);
  final TestBuilderResult result = await testBuilders(
    <Builder>[scanner, aggregator],
    buildTestAssets(extraAssets),
    rootPackage: 'my_app',
    onLog: logs.add,
    visibleOutputBuilders: <Builder>{aggregator},
  );
  final AssetId g = AssetId('my_app', 'lib/showfase.g.dart');
  String? generated;
  if (result.outputs.contains(g)) {
    generated = utf8.decode(await result.readerWriter.readAsBytes(g));
  }
  return _RunResult(generated, logs);
}

class _RunResult {
  _RunResult(this.generated, this.logs);
  final String? generated;
  final List<LogRecord> logs;
}

void main() {
  test('generates showfasePreviews() from a top-level @Preview', () async {
    final _RunResult r = await _run(<String, Object>{
      'my_app|lib/foo.dart': '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Primary', group: 'Buttons')
Widget myPreview() => const Widget();
''',
      'my_app|lib/showfase.dart': '''
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

@ShowfaseRoot()
void main() {}
''',
    });
    expect(
      r.generated,
      isNotNull,
      reason: 'showfase.g.dart should be generated',
    );
    expect(r.generated, contains('showfasePreviews'));
    expect(r.generated, contains("name: 'Primary'"));
    expect(r.generated, contains("group: 'Buttons'"));
    expect(r.generated, contains('.transform()'));
    expect(r.generated, contains('myPreview()'));
  });

  test('handles MultiPreview subclasses', () async {
    final _RunResult r = await _run(<String, Object>{
      'my_app|lib/foo.dart': r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/src/ui.dart';

final class BrightnessPreview extends MultiPreview {
  const BrightnessPreview();
  @override
  // ignore: avoid_field_initializers_in_const_classes
  final List<Preview> previews = const <Preview>[
    Preview(name: 'Light', brightness: Brightness.light),
    Preview(name: 'Dark', brightness: Brightness.dark),
  ];
}

@BrightnessPreview()
Widget myPreview() => const Widget();
''',
      'my_app|lib/showfase.dart': '''
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

@ShowfaseRoot()
void main() {}
''',
    });
    expect(r.generated, isNotNull);
    expect(r.generated, contains('buildShowfaseMultiPreview'));
    expect(r.generated, contains('BrightnessPreview'));
  });

  test(
    'emits static-method and constructor previews with qualified names',
    () async {
      final _RunResult r = await _run(<String, Object>{
        'my_app|lib/foo.dart': '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class MyWidget extends Widget {
  const MyWidget();
  @Preview(name: 'Constructor preview')
  const MyWidget.preview();

  @Preview(name: 'Static preview')
  static Widget staticPreview() => const Widget();
}
''',
        'my_app|lib/showfase.dart': '''
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

@ShowfaseRoot()
void main() {}
''',
      });
      expect(r.generated, isNotNull);
      expect(r.generated, contains('MyWidget.preview'));
      expect(r.generated, contains('MyWidget.staticPreview'));
    },
  );

  test('errors on multiple @ShowfaseRoot annotations in one library', () async {
    final _RunResult r = await _run(<String, Object>{
      'my_app|lib/showfase.dart': '''
import 'package:showfase_annotation/showfase_annotation.dart';

@ShowfaseRoot()
void first() {}

@ShowfaseRoot()
void second() {}
''',
    });
    expect(
      r.generated,
      isNull,
      reason: 'errored builds should not emit output',
    );
    expect(
      r.logs.map((LogRecord l) => l.message).join('\n'),
      contains('Found 2 @ShowfaseRoot annotations'),
    );
  });
}
