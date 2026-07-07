import 'package:code_builder/code_builder.dart' as cb;

import 'const_node.dart';
import 'dart_literal.dart';

/// Rebuilds a [ConstNode] tree into a `code_builder` const expression.
///
/// The returned expression can be dropped into a `const` context in the
/// generated source. Import URIs stored inside the tree are threaded through
/// `code_builder`'s allocator so the emitted file uses prefixed imports.
cb.Expression emitConst(ConstNode node) {
  return switch (node) {
    ConstNull() => cb.literalNull,
    ConstBool(:final value) => cb.literalBool(value),
    ConstInt(:final value) => cb.literalNum(value),
    ConstDouble(:final value) => _emitDouble(value),
    ConstString(:final value) => literalStringLiteral(value),
    ConstSymbol(:final value) => _literalSymbol(value),
    ConstType(:final symbol, :final libraryUri) => cb.refer(symbol, libraryUri),
    ConstEnum(:final symbol, :final libraryUri, :final value) => cb.refer(
      '$symbol.$value',
      libraryUri,
    ),
    ConstTearoff(:final name, :final libraryUri) => cb.refer(name, libraryUri),
    ConstList(
      :final items,
      :final elementTypeSymbol,
      :final elementTypeLibraryUri,
    ) =>
      cb.literalConstList(
        items.map(emitConst).toList(growable: false),
        elementTypeSymbol == null
            ? null
            : cb.refer(elementTypeSymbol, elementTypeLibraryUri),
      ),
    ConstSet(
      :final items,
      :final elementTypeSymbol,
      :final elementTypeLibraryUri,
    ) =>
      cb.literalConstSet(
        items.map(emitConst).toSet(),
        elementTypeSymbol == null
            ? null
            : cb.refer(elementTypeSymbol, elementTypeLibraryUri),
      ),
    ConstMap(:final entries) => cb.literalConstMap(<Object?, Object?>{
      for (final ConstMapEntry e in entries)
        emitConst(e.key): emitConst(e.value),
    }),
    ConstInstance(
      :final symbol,
      :final libraryUri,
      :final constructor,
      :final positional,
      :final named,
    ) =>
      cb.InvokeExpression.constOf(
        cb.refer(symbol, libraryUri),
        positional.map(emitConst).toList(growable: false),
        named.map((k, v) => MapEntry(k, emitConst(v))),
        const <cb.Reference>[],
        constructor,
      ),
  };
}

cb.Expression _literalSymbol(String value) =>
    cb.CodeExpression(cb.Code('#$value'));

cb.Expression _emitDouble(double value) {
  if (value.isNaN) return const cb.CodeExpression(cb.Code('double.nan'));
  if (value == double.infinity) {
    return const cb.CodeExpression(cb.Code('double.infinity'));
  }
  if (value == double.negativeInfinity) {
    return const cb.CodeExpression(cb.Code('double.negativeInfinity'));
  }
  return cb.literalNum(value);
}
