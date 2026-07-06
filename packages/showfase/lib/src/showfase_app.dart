import 'package:flutter/material.dart';

import 'showfase_browser.dart';
import 'showfase_preview.dart';

/// A standalone catalog app: a `MaterialApp` wrapped around
/// [ShowfaseBrowser].
///
/// Typical usage in an entry point:
///
/// ```dart
/// import 'showfase.g.dart';
///
/// void main() => runApp(ShowfaseApp(previews: showfasePreviews()));
/// ```
///
/// To embed the catalog inside an existing app instead, use [ShowfaseBrowser]
/// directly.
class ShowfaseApp extends StatelessWidget {
  const ShowfaseApp({
    super.key,
    required this.previews,
    this.title = 'Showfase',
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
  });

  final List<ShowfasePreview> previews;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: theme ?? ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme:
          darkTheme ??
          ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
      themeMode: themeMode,
      home: ShowfaseBrowser(previews: previews, title: title),
    );
  }
}
