import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads real fonts into the test environment so text renders with actual
/// glyphs instead of the flutter_test placeholder font.
class FontBuilder {
  const FontBuilder._();

  /// Loads every font family declared in the asset bundle's
  /// `FontManifest.json`, plus [additionalFonts] — a map of font family to
  /// font file paths for fonts outside the asset bundle.
  static Future<void> loadFonts({
    Map<String, List<String>> additionalFonts = const <String, List<String>>{},
  }) async {
    await _loadFontManifest();
    for (final MapEntry<String, List<String>> entry
        in additionalFonts.entries) {
      final FontLoader loader = FontLoader(entry.key);
      for (final String path in entry.value) {
        loader.addFont(
          Future<ByteData>.value(
            File(path).readAsBytesSync().buffer.asByteData(),
          ),
        );
      }
      await loader.load();
    }
  }

  static Future<void> _loadFontManifest() async {
    final List<dynamic> manifest;
    try {
      manifest = await rootBundle.loadStructuredData(
        'FontManifest.json',
        (String data) async => json.decode(data) as List<dynamic>,
      );
    } on Object {
      // No asset bundle (e.g. pure package tests) — the deterministic
      // FlutterTest font remains in effect.
      return;
    }

    for (final dynamic familyEntry in manifest) {
      final Map<String, dynamic>? family = familyEntry as Map<String, dynamic>?;
      final String familyName = family?['family'] as String? ?? '';
      final List<dynamic> fonts = family?['fonts'] as List<dynamic>? ?? [];

      final FontLoader loader = FontLoader(familyName);
      for (final dynamic font in fonts) {
        final String asset = (font as Map<String, dynamic>)['asset'] as String;
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  }
}
