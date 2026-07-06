/// Marks the code-generation anchor for a showfase catalog.
///
/// Apply `@ShowfaseRoot()` to the `main` function of the catalog app (or to
/// the top-level widget class that hosts it). The `showfase_generator` builder
/// scans the annotated declaration's library and emits a sibling
/// `<library>.g.dart` that defines a top-level `showfasePreviews()` function.
///
/// Exactly one declaration in a package must carry this annotation. If none
/// is found — or more than one — the builder produces a build-time error.
///
/// ## Example
///
/// ```dart
/// // lib/showfase.dart
/// import 'package:flutter/material.dart';
/// import 'package:showfase/showfase.dart';
/// import 'package:showfase_annotation/showfase_annotation.dart';
///
/// import 'showfase.g.dart';
///
/// @ShowfaseRoot()
/// void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
/// ```
class ShowfaseRoot {
  /// Marks this declaration as the anchor for the generated catalog.
  const ShowfaseRoot();
}
