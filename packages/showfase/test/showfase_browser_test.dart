import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';

const _buttonKey = ValueKey<String>('button');
const _cardKey = ValueKey<String>('card');

Widget _buttonPreview() =>
    Container(key: _buttonKey, width: 120, height: 40, color: Colors.blue);
Widget _cardPreview() =>
    Container(key: _cardKey, width: 200, height: 100, color: Colors.red);

ShowfasePreview _buttonEntry() => const ShowfasePreview(
  id: 'a#button',
  previewData: Preview(name: 'Primary', group: 'Buttons'),
  builder: _buttonPreview,
);

ShowfasePreview _cardEntry() => const ShowfasePreview(
  id: 'a#card',
  previewData: Preview(name: 'Wide', group: 'Cards'),
  builder: _cardPreview,
);

void main() {
  testWidgets('lists previews grouped, and navigates to detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShowfaseApp(previews: <ShowfasePreview>[_buttonEntry(), _cardEntry()]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buttons  ·  1'), findsOneWidget);
    expect(find.text('Cards  ·  1'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);

    await tester.tap(find.text('Primary'));
    await tester.pumpAndSettle();
    // On the detail screen: canvas should render the button.
    expect(find.byKey(_buttonKey), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
  });

  testWidgets('search filters previews by name', (tester) async {
    await tester.pumpWidget(
      ShowfaseApp(previews: <ShowfasePreview>[_buttonEntry(), _cardEntry()]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'card');
    await tester.pump();

    expect(find.text('Primary'), findsNothing);
    expect(find.text('Wide'), findsOneWidget);
  });

  testWidgets('detail screen renders text-scale control', (tester) async {
    await tester.pumpWidget(
      ShowfaseApp(previews: <ShowfasePreview>[_buttonEntry()]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primary'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('Text scale:'), findsOneWidget);
  });

  testWidgets('canvas applies preview size', (tester) async {
    const ShowfasePreview sized = ShowfasePreview(
      id: 'x#sized',
      previewData: Preview(name: 'Sized', size: Size(80, 30)),
      builder: _buttonPreview,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShowfasePreviewCanvas(preview: sized)),
      ),
    );
    await tester.pumpAndSettle();
    final Size sizeOf = tester.getSize(find.byKey(_buttonKey));
    expect(sizeOf.width, closeTo(80, 0.5));
    expect(sizeOf.height, closeTo(30, 0.5));
  });
}
