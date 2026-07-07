import 'package:code_builder/code_builder.dart' as cb;

/// Emits a Dart string literal for [value], escaping `$` in addition to what
/// [cb.literalString] already escapes (`'` and `\n`).
///
/// `code_builder`'s `literalString` does not escape `$`, so any *data*
/// string (as opposed to source code) that happens to contain a literal `$`
/// — for example a preview `name`/`group` that mentions a price like
/// `'$100'`, or a scanned function name that starts with `$` per the
/// `$PreviewName` convention — gets silently reinterpreted by the Dart
/// parser as string interpolation once written out. `$<digit>` is a hard
/// parse error ("Expected an identifier"); `$<letters>` instead compiles
/// into a reference to an undefined top-level name in the generated
/// library. Escaping here keeps the value a literal string in all cases.
cb.Expression literalStringLiteral(String value) =>
    cb.literalString(value.replaceAll(r'$', r'\$'));
