import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'const_encoder.dart';
import 'const_node.dart';
import 'preview_metadata.dart';
import 'type_checkers.dart';

/// Scans a single Dart library for `@Preview` and `@MultiPreview` annotations
/// and produces one [PreviewMetadata] record per annotation instance.
///
/// Reports invalid targets (private, missing return type, required args, etc.)
/// as warnings via the supplied [log]. Returns an empty list if the library
/// has no matching annotations.
List<PreviewMetadata> scanLibraryForPreviews(
  LibraryElement library, {
  required void Function(String message) log,
}) {
  final List<PreviewMetadata> out = <PreviewMetadata>[];
  final String libraryUri = library.uri.toString();

  for (final TopLevelFunctionElement fn in library.topLevelFunctions) {
    _collectFrom(
      fn,
      kind: PreviewElementKind.topLevelFunction,
      qualifiedName: fn.name ?? '',
      returnType: fn.returnType,
      formalParameters: fn.formalParameters,
      libraryUri: libraryUri,
      out: out,
      log: log,
    );
  }

  for (final ClassElement cls in library.classes) {
    if (cls.isPrivate) continue;
    final String className = cls.name ?? '';

    for (final MethodElement m in cls.methods) {
      if (!m.isStatic || m.isPrivate) continue;
      _collectFrom(
        m,
        kind: PreviewElementKind.staticMethod,
        qualifiedName: '$className.${m.name}',
        returnType: m.returnType,
        formalParameters: m.formalParameters,
        libraryUri: libraryUri,
        out: out,
        log: log,
      );
    }

    for (final ConstructorElement c in cls.constructors) {
      if (c.isPrivate) continue;
      final String? rawCtor = c.name;
      final String qualifiedName =
          (rawCtor == null || rawCtor.isEmpty || rawCtor == 'new')
              ? className
              : '$className.$rawCtor';
      _collectFrom(
        c,
        kind: PreviewElementKind.constructor,
        qualifiedName: qualifiedName,
        returnType: null, // Not applicable — constructors always return the class.
        formalParameters: c.formalParameters,
        libraryUri: libraryUri,
        out: out,
        log: log,
      );
    }
  }

  return out;
}

void _collectFrom(
  Element element, {
  required PreviewElementKind kind,
  required String qualifiedName,
  required DartType? returnType,
  required List<FormalParameterElement> formalParameters,
  required String libraryUri,
  required List<PreviewMetadata> out,
  required void Function(String message) log,
}) {
  final List<_AnnotationHit> hits = _findPreviewAnnotations(element);
  if (hits.isEmpty) return;

  // Constructors and methods with required arguments cannot be previewed.
  if (formalParameters.any((FormalParameterElement p) => p.isRequired)) {
    log(
      '@Preview on $qualifiedName ignored: previews may not have required '
      'parameters.',
    );
    return;
  }

  // Functions and methods must return Widget or WidgetBuilder.
  bool isBuilder = false;
  if (kind != PreviewElementKind.constructor) {
    final _ReturnKind rk = _classifyReturnType(returnType);
    if (rk == _ReturnKind.unsupported) {
      final String seen = returnType?.getDisplayString() ?? '<none>';
      log(
        '@Preview on $qualifiedName ignored: return type must be Widget or '
        'WidgetBuilder, got $seen.',
      );
      return;
    }
    isBuilder = rk == _ReturnKind.widgetBuilder;
  }

  for (final _AnnotationHit hit in hits) {
    final ConstNode encoded;
    try {
      encoded = encodeConstant(hit.value);
    } on ConstEncodingException catch (e) {
      log('@Preview on $qualifiedName skipped: ${e.message}');
      continue;
    }
    out.add(
      PreviewMetadata(
        function: qualifiedName,
        libraryUri: libraryUri,
        kind: kind,
        isBuilder: isBuilder,
        isMultiPreview: hit.isMultiPreview,
        annotation: encoded,
      ),
    );
  }
}

class _AnnotationHit {
  const _AnnotationHit({required this.value, required this.isMultiPreview});
  final DartObject value;
  final bool isMultiPreview;
}

List<_AnnotationHit> _findPreviewAnnotations(Element element) {
  final List<_AnnotationHit> hits = <_AnnotationHit>[];
  for (final DartObject obj in previewChecker.annotationsOf(element)) {
    hits.add(_AnnotationHit(value: obj, isMultiPreview: false));
  }
  for (final DartObject obj in multiPreviewChecker.annotationsOf(element)) {
    hits.add(_AnnotationHit(value: obj, isMultiPreview: true));
  }
  return hits;
}

enum _ReturnKind { widget, widgetBuilder, unsupported }

_ReturnKind _classifyReturnType(DartType? type) {
  if (type == null) return _ReturnKind.unsupported;
  // The type may be a typedef instantiation — `WidgetBuilder` resolves to
  // `Widget Function(BuildContext)`. Prefer the alias name when present so
  // typedef targets are treated identically to their alias.
  final String? aliasName = type.alias?.element.name;
  if (aliasName == 'WidgetBuilder') return _ReturnKind.widgetBuilder;
  final String display = type.getDisplayString();
  if (display == 'Widget') return _ReturnKind.widget;
  if (display == 'WidgetBuilder') return _ReturnKind.widgetBuilder;
  return _ReturnKind.unsupported;
}

/// Convenience wrapper that logs via [BuildStep].
///
/// Kept out of [scanLibraryForPreviews] to keep the core logic testable
/// without a `BuildStep` instance.
List<PreviewMetadata> scanForBuildStep(
  LibraryElement library,
  BuildStep step,
) {
  final String path = step.inputId.toString();
  return scanLibraryForPreviews(
    library,
    log: (String message) => log.warning('[$path] $message'),
  );
}
