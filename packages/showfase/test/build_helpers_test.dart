import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';

const _sentinelKey = ValueKey<String>('sentinel');
Widget _widgetPreview() => const SizedBox.shrink(key: _sentinelKey);
WidgetBuilder _builderPreview() =>
    (BuildContext _) => const SizedBox.shrink(key: _sentinelKey);

final class _LightDark extends MultiPreview {
  const _LightDark();
  @override
  final List<Preview> previews = const <Preview>[
    Preview(name: 'Light', brightness: Brightness.light),
    Preview(name: 'Dark', brightness: Brightness.dark),
  ];
}

void main() {
  group('buildShowfasePreview', () {
    testWidgets('accepts a Widget-returning thunk', (tester) async {
      final ShowfasePreview preview = buildShowfasePreview(
        id: 'lib.dart#p',
        transformedPreview: const Preview(name: 'W', group: 'g'),
        previewFunction: _widgetPreview,
      );
      expect(preview.id, 'lib.dart#p');
      expect(preview.group, 'g');
      expect(preview.name, 'W');
      await tester.pumpWidget(preview.builder());
      expect(find.byKey(_sentinelKey), findsOneWidget);
    });

    testWidgets('accepts a WidgetBuilder-returning thunk', (tester) async {
      final ShowfasePreview preview = buildShowfasePreview(
        id: 'lib.dart#b',
        transformedPreview: const Preview(),
        previewFunction: _builderPreview,
      );
      await tester.pumpWidget(preview.builder());
      expect(find.byKey(_sentinelKey), findsOneWidget);
    });

    test('defaults group to "Default" when unset', () {
      final ShowfasePreview preview = buildShowfasePreview(
        id: 'x',
        transformedPreview: const Preview(),
        previewFunction: _widgetPreview,
      );
      expect(preview.group, 'Default');
      expect(preview.name, isNull);
    });
  });

  group('buildShowfaseMultiPreview', () {
    test('expands each Preview into a distinct entry', () {
      final List<ShowfasePreview> expanded = buildShowfaseMultiPreview(
        id: 'lib.dart#m',
        multiPreview: const _LightDark(),
        previewFunction: _widgetPreview,
      ).toList();
      expect(expanded, hasLength(2));
      expect(expanded[0].id, 'lib.dart#m#0');
      expect(expanded[0].name, 'Light');
      expect(expanded[1].id, 'lib.dart#m#1');
      expect(expanded[1].previewData.brightness, Brightness.dark);
    });
  });
}
