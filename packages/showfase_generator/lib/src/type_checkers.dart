import 'package:source_gen/source_gen.dart';

/// Matches Flutter's `Preview` annotation (and any user-defined subclass).
///
/// We match by literal name + package, not import URL, because `Preview` is
/// re-exported from `package:flutter/widget_previews.dart` while its origin
/// lives under `src/`. This form stays valid if Flutter reorganizes files
/// within the same package.
const TypeChecker previewChecker = TypeChecker.typeNamedLiterally(
  'Preview',
  inPackage: 'flutter',
);

/// Matches Flutter's `MultiPreview` annotation and its subclasses.
const TypeChecker multiPreviewChecker = TypeChecker.typeNamedLiterally(
  'MultiPreview',
  inPackage: 'flutter',
);

/// Matches `Widget` from Flutter's widgets library.
const TypeChecker widgetChecker = TypeChecker.typeNamedLiterally(
  'Widget',
  inPackage: 'flutter',
);

/// Matches Flutter's `ShowfaseRoot` annotation.
const TypeChecker showfaseRootChecker = TypeChecker.typeNamedLiterally(
  'ShowfaseRoot',
  inPackage: 'showfase_annotation',
);
