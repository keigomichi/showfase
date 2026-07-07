import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';

import 'const_emitter.dart';
import 'dart_literal.dart';
import 'preview_metadata.dart';
import 'type_checkers.dart';

const String _showfaseRuntimeUri = 'package:showfase/showfase.dart';

/// Aggregating generator that reacts to `@ShowfaseRoot` and emits a
/// `showfasePreviews()` function backed by every `.showfase.json` intermediate
/// produced by the phase-1 scanner in the same package.
class ShowfaseAggregator extends GeneratorForAnnotation<Object> {
  const ShowfaseAggregator();

  @override
  TypeChecker get typeChecker => showfaseRootChecker;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final List<AnnotatedElement> annotated = library
        .annotatedWith(typeChecker)
        .toList();
    if (annotated.isEmpty) return '';
    if (annotated.length > 1) {
      throw InvalidGenerationSourceError(
        'Found ${annotated.length} @ShowfaseRoot annotations in one library. '
        'Exactly one is allowed.',
        element: annotated.first.element,
      );
    }
    return _emitLibrary(await _collectMetadata(buildStep));
  }

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Superseded by [generate] above (which handles multi-annotation checks).
    // Should never be reached.
    return '';
  }
}

Future<List<PreviewMetadata>> _collectMetadata(BuildStep step) async {
  final Glob glob = Glob('**.showfase.json');
  final List<PreviewMetadata> all = <PreviewMetadata>[];
  await for (final AssetId asset in step.findAssets(glob)) {
    final String raw = await step.readAsString(asset);
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) continue;
    for (final Object? entry in decoded) {
      if (entry is Map<String, Object?>) {
        all.add(PreviewMetadata.fromJson(entry));
      }
    }
  }
  all.sort((PreviewMetadata a, PreviewMetadata b) {
    final int c = a.libraryUri.compareTo(b.libraryUri);
    if (c != 0) return c;
    final int c2 = a.function.compareTo(b.function);
    if (c2 != 0) return c2;
    return (a.line ?? 0).compareTo(b.line ?? 0);
  });
  return all;
}

String _emitLibrary(List<PreviewMetadata> previews) {
  final cb.Library lib = cb.Library(
    (cb.LibraryBuilder b) => b
      ..ignoreForFile.addAll(<String>['type=lint', 'implementation_imports'])
      ..body.add(
        cb.Method(
          (cb.MethodBuilder m) => m
            ..name = 'showfasePreviews'
            ..returns = cb.TypeReference(
              (cb.TypeReferenceBuilder t) => t
                ..symbol = 'List'
                ..url = 'dart:core'
                ..types.add(cb.refer('ShowfasePreview', _showfaseRuntimeUri)),
            )
            ..body = cb.literalList(<cb.Expression>[
              for (final PreviewMetadata p in previews) _emitEntry(p),
            ]).code,
        ),
      ),
  );

  final cb.DartEmitter emitter = cb.DartEmitter.scoped(
    useNullSafetySyntax: true,
  );
  final String source = lib.accept(emitter).toString();
  final DartFormatter formatter = DartFormatter(
    languageVersion: Version(3, 11, 0),
  );
  return formatter.format(source);
}

cb.Expression _emitEntry(PreviewMetadata p) {
  final String id = '${p.libraryUri}#${p.function}';
  final cb.Expression annotationExpr = emitConst(p.annotation);
  final cb.Expression previewClosure = cb.Method(
    (cb.MethodBuilder m) => m..body = _invokeTargetExpression(p).code,
  ).closure;

  final Map<String, cb.Expression> args = <String, cb.Expression>{
    'id': literalStringLiteral(id),
    'scriptUri': literalStringLiteral(p.libraryUri),
    'previewFunction': previewClosure,
  };
  if (p.line != null) args['line'] = cb.literalNum(p.line!);
  if (p.column != null) args['column'] = cb.literalNum(p.column!);

  if (p.isMultiPreview) {
    return cb.refer('buildShowfaseMultiPreview', _showfaseRuntimeUri).call(
      <cb.Expression>[],
      <String, cb.Expression>{...args, 'multiPreview': annotationExpr},
    ).spread;
  }
  return cb
      .refer('buildShowfasePreview', _showfaseRuntimeUri)
      .call(<cb.Expression>[], <String, cb.Expression>{
        ...args,
        'transformedPreview': annotationExpr
            .property('transform')
            .call(<cb.Expression>[]),
      });
}

cb.Expression _invokeTargetExpression(PreviewMetadata p) {
  return switch (p.kind) {
    PreviewElementKind.topLevelFunction =>
      cb.refer(p.function, p.libraryUri).call(<cb.Expression>[]),
    PreviewElementKind.staticMethod =>
      cb.refer(p.function, p.libraryUri).call(<cb.Expression>[]),
    PreviewElementKind.constructor =>
      cb.refer(p.function, p.libraryUri).newInstance(<cb.Expression>[]),
  };
}
