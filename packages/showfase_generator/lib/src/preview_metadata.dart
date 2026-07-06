import 'const_node.dart';

/// Kind of Dart element the `@Preview` was applied to.
enum PreviewElementKind { topLevelFunction, staticMethod, constructor }

/// A single preview record extracted from a source library.
///
/// Written to `<library>.showfase.json` by the phase-1 scanner and read back
/// by the phase-2 aggregating builder.
class PreviewMetadata {
  const PreviewMetadata({
    required this.function,
    required this.libraryUri,
    required this.kind,
    required this.isBuilder,
    required this.isMultiPreview,
    required this.annotation,
    this.line,
    this.column,
  });

  /// Qualified function name.
  ///
  /// * For a top-level function: the function name (`myPreview`).
  /// * For a static method: `ClassName.methodName`.
  /// * For a constructor: `ClassName` (unnamed) or `ClassName.name`.
  final String function;

  /// URI of the library containing the annotated element (e.g.
  /// `package:app/src/foo.dart`).
  final String libraryUri;

  /// Kind of Dart element the annotation was applied to.
  final PreviewElementKind kind;

  /// Whether the element returns a `WidgetBuilder` instead of a `Widget`.
  ///
  /// Constructors never return a `WidgetBuilder`, so this is always `false`
  /// when [kind] is [PreviewElementKind.constructor].
  final bool isBuilder;

  /// Whether the annotation is a subtype of `MultiPreview` rather than
  /// `Preview`.
  final bool isMultiPreview;

  /// Encoded annotation value, ready for emission as a `const` expression.
  final ConstNode annotation;

  /// 1-based line of the annotation, if known.
  final int? line;

  /// 1-based column of the annotation, if known.
  final int? column;

  Map<String, Object?> toJson() => <String, Object?>{
    'function': function,
    'libraryUri': libraryUri,
    'kind': kind.name,
    'isBuilder': isBuilder,
    'isMultiPreview': isMultiPreview,
    'annotation': annotation.toJson(),
    if (line != null) 'line': line,
    if (column != null) 'column': column,
  };

  static PreviewMetadata fromJson(Map<String, Object?> json) => PreviewMetadata(
    function: json['function']! as String,
    libraryUri: json['libraryUri']! as String,
    kind: PreviewElementKind.values.byName(json['kind']! as String),
    isBuilder: json['isBuilder']! as bool,
    isMultiPreview: json['isMultiPreview']! as bool,
    annotation: ConstNode.fromJson(json['annotation']! as Map<String, Object?>),
    line: json['line'] as int?,
    column: json['column'] as int?,
  );
}
