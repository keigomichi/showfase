import 'dart:convert';

import 'package:showfase_generator/showfase_generator.dart';
import 'package:test/test.dart';

void main() {
  group('ConstNode JSON round-trip', () {
    void roundTrip(ConstNode input) {
      final String encoded = jsonEncode(input.toJson());
      final ConstNode decoded = ConstNode.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
      expect(jsonEncode(decoded.toJson()), encoded);
    }

    test('primitives', () {
      roundTrip(const ConstNull());
      roundTrip(const ConstBool(true));
      roundTrip(const ConstInt(42));
      roundTrip(const ConstDouble(3.14));
      roundTrip(const ConstString('hello'));
      roundTrip(const ConstSymbol('foo'));
    });

    test('enum ref', () {
      roundTrip(const ConstEnum(
        symbol: 'Brightness',
        libraryUri: 'dart:ui',
        value: 'dark',
      ));
    });

    test('tearoff', () {
      roundTrip(const ConstTearoff(
        name: 'AppScope.wrap',
        libraryUri: 'package:app/scopes.dart',
      ));
    });

    test('nested instance', () {
      roundTrip(const ConstInstance(
        symbol: 'Preview',
        libraryUri: 'package:flutter/widget_previews.dart',
        named: <String, ConstNode>{
          'name': ConstString('Primary'),
          'size': ConstInstance(
            symbol: 'Size',
            libraryUri: 'dart:ui',
            positional: <ConstNode>[ConstDouble(200), ConstDouble(100)],
          ),
          'brightness': ConstEnum(
            symbol: 'Brightness',
            libraryUri: 'dart:ui',
            value: 'dark',
          ),
        },
      ));
    });

    test('list', () {
      roundTrip(const ConstList(<ConstNode>[
        ConstInt(1),
        ConstInt(2),
        ConstInt(3),
      ]));
    });

    test('map', () {
      roundTrip(const ConstMap(entries: <ConstMapEntry>[
        (key: ConstString('a'), value: ConstInt(1)),
        (key: ConstString('b'), value: ConstInt(2)),
      ]));
    });
  });
}
