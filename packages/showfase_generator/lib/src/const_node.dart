/// Serializable representation of a Dart compile-time constant.
///
/// The generator walks each `@Preview` / `@MultiPreview` annotation as an
/// analyzer `DartObject`, encodes it into a tree of these nodes, and writes
/// the tree to `.showfase.json`. The aggregating builder later decodes the
/// tree back into a `code_builder.Expression` that reconstructs the
/// annotation as a `const` expression in generated code.
///
/// This detour through JSON — instead of decomposing the annotation into a
/// fixed schema — lets the generator support:
///
///   * arbitrary user-defined `Preview` / `MultiPreview` subclasses,
///   * `Preview.transform()` overrides (evaluated at runtime),
///   * nested const values (`Size(w, h)`, enums, records),
///   * function-typed fields (`wrapper`, `theme`, `localizations`) rebuilt
///     as tear-off references,
///
/// without hard-coding the current `Preview` field list.
library;

/// Base class for the const-value tree.
sealed class ConstNode {
  const ConstNode();

  Map<String, Object?> toJson();

  static ConstNode fromJson(Map<String, Object?> json) {
    final String type = json['type']! as String;
    return switch (type) {
      'null' => const ConstNull(),
      'bool' => ConstBool(json['value']! as bool),
      'int' => ConstInt(json['value']! as int),
      'double' => ConstDouble(_readDouble(json['value']!)),
      'string' => ConstString(json['value']! as String),
      'symbol' => ConstSymbol(json['value']! as String),
      'type' => ConstType(
          symbol: json['symbol']! as String,
          libraryUri: json['libraryUri'] as String?,
        ),
      'enum' => ConstEnum(
          symbol: json['symbol']! as String,
          libraryUri: json['libraryUri']! as String,
          value: json['value']! as String,
        ),
      'tearoff' => ConstTearoff(
          name: json['name']! as String,
          libraryUri: json['libraryUri'] as String?,
        ),
      'list' => ConstList(
          (json['items']! as List<Object?>)
              .map((e) => ConstNode.fromJson(e! as Map<String, Object?>))
              .toList(),
          elementTypeSymbol: json['elementTypeSymbol'] as String?,
          elementTypeLibraryUri: json['elementTypeLibraryUri'] as String?,
        ),
      'set' => ConstSet(
          (json['items']! as List<Object?>)
              .map((e) => ConstNode.fromJson(e! as Map<String, Object?>))
              .toList(),
          elementTypeSymbol: json['elementTypeSymbol'] as String?,
          elementTypeLibraryUri: json['elementTypeLibraryUri'] as String?,
        ),
      'map' => ConstMap(
          entries: (json['entries']! as List<Object?>).map((e) {
            final Map<String, Object?> pair = e! as Map<String, Object?>;
            return (
              key: ConstNode.fromJson(pair['key']! as Map<String, Object?>),
              value: ConstNode.fromJson(pair['value']! as Map<String, Object?>),
            );
          }).toList(),
        ),
      'instance' => ConstInstance(
          symbol: json['symbol']! as String,
          libraryUri: json['libraryUri']! as String,
          constructor: json['constructor'] as String?,
          positional: (json['positional']! as List<Object?>)
              .map((e) => ConstNode.fromJson(e! as Map<String, Object?>))
              .toList(),
          named: (json['named']! as Map<String, Object?>).map(
            (k, v) => MapEntry(k, ConstNode.fromJson(v! as Map<String, Object?>)),
          ),
        ),
      _ => throw StateError('Unknown ConstNode type: $type'),
    };
  }
}

final class ConstNull extends ConstNode {
  const ConstNull();
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'null'};
}

final class ConstBool extends ConstNode {
  const ConstBool(this.value);
  final bool value;
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'bool', 'value': value};
}

final class ConstInt extends ConstNode {
  const ConstInt(this.value);
  final int value;
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'int', 'value': value};
}

final class ConstDouble extends ConstNode {
  const ConstDouble(this.value);
  final double value;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'double',
        // JSON has no representation for non-finite doubles, so serialize
        // them as tagged strings and reconstruct on decode.
        'value': value.isFinite ? value : _encodeSpecial(value),
      };
}

Object _encodeSpecial(double v) {
  if (v.isNaN) return '__nan__';
  if (v == double.infinity) return '__inf__';
  if (v == double.negativeInfinity) return '__ninf__';
  return v; // unreachable
}

double _readDouble(Object raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    return switch (raw) {
      '__nan__' => double.nan,
      '__inf__' => double.infinity,
      '__ninf__' => double.negativeInfinity,
      _ => throw StateError('Unknown double marker: $raw'),
    };
  }
  throw StateError('Invalid double value: $raw (${raw.runtimeType})');
}

final class ConstString extends ConstNode {
  const ConstString(this.value);
  final String value;
  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'type': 'string', 'value': value};
}

final class ConstSymbol extends ConstNode {
  const ConstSymbol(this.value);
  final String value;
  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'type': 'symbol', 'value': value};
}

final class ConstType extends ConstNode {
  const ConstType({required this.symbol, this.libraryUri});
  final String symbol;
  final String? libraryUri;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'type',
        'symbol': symbol,
        if (libraryUri != null) 'libraryUri': libraryUri,
      };
}

/// A reference to an enum constant, e.g. `Brightness.dark`.
final class ConstEnum extends ConstNode {
  const ConstEnum({
    required this.symbol,
    required this.libraryUri,
    required this.value,
  });
  final String symbol;
  final String libraryUri;
  final String value;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'enum',
        'symbol': symbol,
        'libraryUri': libraryUri,
        'value': value,
      };
}

/// A reference to a top-level or static function, emitted as a tear-off.
///
/// `name` includes any enclosing-class qualifier (e.g. `AppScope.wrap`).
final class ConstTearoff extends ConstNode {
  const ConstTearoff({required this.name, this.libraryUri});
  final String name;
  final String? libraryUri;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'tearoff',
        'name': name,
        if (libraryUri != null) 'libraryUri': libraryUri,
      };
}

final class ConstList extends ConstNode {
  const ConstList(this.items, {this.elementTypeSymbol, this.elementTypeLibraryUri});
  final List<ConstNode> items;
  final String? elementTypeSymbol;
  final String? elementTypeLibraryUri;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'list',
        'items': items.map((n) => n.toJson()).toList(),
        if (elementTypeSymbol != null) 'elementTypeSymbol': elementTypeSymbol,
        if (elementTypeLibraryUri != null)
          'elementTypeLibraryUri': elementTypeLibraryUri,
      };
}

final class ConstSet extends ConstNode {
  const ConstSet(this.items, {this.elementTypeSymbol, this.elementTypeLibraryUri});
  final List<ConstNode> items;
  final String? elementTypeSymbol;
  final String? elementTypeLibraryUri;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'set',
        'items': items.map((n) => n.toJson()).toList(),
        if (elementTypeSymbol != null) 'elementTypeSymbol': elementTypeSymbol,
        if (elementTypeLibraryUri != null)
          'elementTypeLibraryUri': elementTypeLibraryUri,
      };
}

typedef ConstMapEntry = ({ConstNode key, ConstNode value});

final class ConstMap extends ConstNode {
  const ConstMap({required this.entries});
  final List<ConstMapEntry> entries;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'map',
        'entries': entries
            .map((e) => <String, Object?>{
                  'key': e.key.toJson(),
                  'value': e.value.toJson(),
                })
            .toList(),
      };
}

/// A const constructor invocation of a class (`Preview(...)`, `Size(...)`,
/// custom `MultiPreview` subclass, etc.).
final class ConstInstance extends ConstNode {
  const ConstInstance({
    required this.symbol,
    required this.libraryUri,
    this.constructor,
    this.positional = const <ConstNode>[],
    this.named = const <String, ConstNode>{},
  });
  final String symbol;
  final String libraryUri;
  final String? constructor;
  final List<ConstNode> positional;
  final Map<String, ConstNode> named;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'instance',
        'symbol': symbol,
        'libraryUri': libraryUri,
        if (constructor != null) 'constructor': constructor,
        'positional': positional.map((n) => n.toJson()).toList(),
        'named': named.map((k, v) => MapEntry(k, v.toJson())),
      };
}
