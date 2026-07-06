import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// A single preview entry displayed by the showfase browser.
///
/// Each entry pairs a widget-building closure with the `Preview` metadata
/// captured by the code generator. The metadata drives grouping, sizing,
/// theming and other environmental settings applied by the browser.
class ShowfasePreview {
  /// Creates a preview entry.
  const ShowfasePreview({
    required this.id,
    required this.builder,
    required this.previewData,
    this.scriptUri,
    this.line,
    this.column,
  });

  /// Stable identifier used for state persistence and deep-linking.
  ///
  /// The generator produces ids of the form
  /// `<libraryUri>#<functionName>[#<index>]`. Callers must not depend on the
  /// exact shape.
  final String id;

  /// Builds the previewed widget.
  ///
  /// Called every time the preview is rendered — the browser applies
  /// environment overrides around this call.
  final Widget Function() builder;

  /// Metadata extracted from the `@Preview()` annotation, after
  /// `Preview.transform()` has been applied.
  final Preview previewData;

  /// Source-file location of the annotation, if known.
  final String? scriptUri;

  /// 1-based line of the annotation, if known.
  final int? line;

  /// 1-based column of the annotation, if known.
  final int? column;

  /// The group name; defaults to `'Default'`.
  String get group => previewData.group;

  /// The preview's display name, or `null` when unset.
  String? get name => previewData.name;
}
