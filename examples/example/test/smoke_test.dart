import 'package:flutter_test/flutter_test.dart';
import 'package:showfase_example/showfase.g.dart';

void main() {
  test('generated catalog has entries', () {
    final list = showfasePreviews();
    expect(list, isNotEmpty);
    // Sanity-check that the well-known example previews are all captured.
    final Set<String> names = <String>{
      for (final p in list) p.name ?? '(unnamed)',
    };
    expect(names, containsAll(<String>[
      'Simple button',
      'Constructor preview',
      'Static preview',
      'Factory preview',
      'Builder-returning',
      'Fixed width',
      'Large text',
      'Dark mode',
      'With wrapper',
      'Light',
      'Dark',
      'Stacked A',
      'Stacked B',
    ]));
  });
}
