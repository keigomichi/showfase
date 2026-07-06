import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'const_node.dart';

/// Thrown when a value inside an annotation cannot be encoded.
///
/// Callers should skip the offending preview and log a warning that names the
/// annotated function so the developer can fix the annotation or file an
/// issue.
class ConstEncodingException implements Exception {
  ConstEncodingException(this.message);
  final String message;
  @override
  String toString() => 'ConstEncodingException: $message';
}

/// Encodes a compile-time constant [DartObject] into a [ConstNode] tree.
///
/// The tree is JSON-serializable and later decoded by the aggregating builder
/// into a `code_builder` expression that reconstructs the annotation as a
/// `const` expression in generated code.
ConstNode encodeConstant(DartObject object) {
  final DartType? type = object.type;
  if (type == null) {
    throw ConstEncodingException('DartObject has no type: $object');
  }

  if (type.isDartCoreNull || object.isNull) return const ConstNull();
  if (type.isDartCoreBool) return ConstBool(object.toBoolValue()!);
  if (type.isDartCoreInt) return ConstInt(object.toIntValue()!);
  if (type.isDartCoreDouble) return ConstDouble(object.toDoubleValue()!);
  if (type.isDartCoreString) return ConstString(object.toStringValue()!);
  if (type.isDartCoreSymbol) {
    return ConstSymbol(object.toSymbolValue()!);
  }
  if (type.isDartCoreType) {
    return _encodeType(object.toTypeValue()!);
  }

  final List<DartObject>? list = object.toListValue();
  if (list != null) {
    return ConstList(
      list.map(encodeConstant).toList(growable: false),
      elementTypeSymbol: _elementTypeSymbol(type),
      elementTypeLibraryUri: _elementTypeLibraryUri(type),
    );
  }
  final Set<DartObject>? set = object.toSetValue();
  if (set != null) {
    return ConstSet(
      set.map(encodeConstant).toList(growable: false),
      elementTypeSymbol: _elementTypeSymbol(type),
      elementTypeLibraryUri: _elementTypeLibraryUri(type),
    );
  }
  final Map<DartObject?, DartObject?>? map = object.toMapValue();
  if (map != null) {
    final List<ConstMapEntry> entries = <ConstMapEntry>[];
    for (final MapEntry<DartObject?, DartObject?> e in map.entries) {
      if (e.key == null || e.value == null) {
        throw ConstEncodingException('Map entry has null key or value');
      }
      entries.add((key: encodeConstant(e.key!), value: encodeConstant(e.value!)));
    }
    return ConstMap(entries: entries);
  }

  // Enum constants show up as objects whose backing `variable` is a
  // `FieldElement.isEnumConstant`.
  final Element? variable = object.variable;
  if (variable is FieldElement && variable.isEnumConstant) {
    final Element enclosing = variable.enclosingElement;
    if (enclosing is EnumElement) {
      return ConstEnum(
        symbol: enclosing.displayName,
        libraryUri: enclosing.library.uri.toString(),
        value: variable.displayName,
      );
    }
  }

  // Function tear-offs.
  final ExecutableElement? fn = object.toFunctionValue();
  if (fn != null) {
    return _encodeTearoff(fn);
  }

  // Const-constructor invocation of a class instance.
  final ConstructorInvocation? invocation = object.constructorInvocation;
  if (invocation != null) {
    return _encodeInstance(type, invocation);
  }

  throw ConstEncodingException(
    'Unsupported constant of type ${type.getDisplayString()}',
  );
}

ConstType _encodeType(DartType type) {
  final String symbol = type.getDisplayString();
  final Element? element = _typeElement(type);
  return ConstType(
    symbol: symbol,
    libraryUri: _libraryUriOf(element),
  );
}

Element? _typeElement(DartType type) {
  if (type is InterfaceType) return type.element;
  return null;
}

String? _elementTypeSymbol(DartType type) {
  if (type is InterfaceType && type.typeArguments.isNotEmpty) {
    return type.typeArguments.first.getDisplayString();
  }
  return null;
}

String? _elementTypeLibraryUri(DartType type) {
  if (type is InterfaceType && type.typeArguments.isNotEmpty) {
    final DartType first = type.typeArguments.first;
    return _libraryUriOf(_typeElement(first));
  }
  return null;
}

String? _libraryUriOf(Element? element) {
  if (element == null) return null;
  final LibraryElement? library = element.library;
  return library?.uri.toString();
}

ConstTearoff _encodeTearoff(ExecutableElement fn) {
  final Element? enclosing = fn.enclosingElement;
  final String name;
  if (enclosing is InterfaceElement) {
    // Static method or (rare) constructor tear-off.
    final String base = fn.displayName;
    name = '${enclosing.displayName}.$base';
  } else {
    name = fn.displayName;
  }
  return ConstTearoff(
    name: name,
    libraryUri: fn.library.uri.toString(),
  );
}

ConstInstance _encodeInstance(DartType type, ConstructorInvocation invocation) {
  final ConstructorElement constructor = invocation.constructor;
  final InterfaceElement enclosing = constructor.enclosingElement;
  final String? rawName = constructor.name;
  final String? ctorName =
      (rawName == null || rawName.isEmpty || rawName == 'new') ? null : rawName;
  return ConstInstance(
    symbol: enclosing.displayName,
    libraryUri: enclosing.library.uri.toString(),
    constructor: ctorName,
    positional: invocation.positionalArguments
        .map(encodeConstant)
        .toList(growable: false),
    named: <String, ConstNode>{
      for (final MapEntry<String, DartObject> e in invocation.namedArguments.entries)
        e.key: encodeConstant(e.value),
    },
  );
}
