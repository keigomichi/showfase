import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'preview_metadata.dart';
import 'preview_scanner.dart';

/// Phase-1 build_runner builder.
///
/// For each `.dart` library in the target package, writes a
/// `<library>.showfase.json` cache file listing every `@Preview` and
/// `@MultiPreview` annotation discovered. Libraries with no matching
/// annotations produce no output.
///
/// The output is consumed by [ShowfaseAggregator] in phase 2.
class PreviewScannerBuilder implements Builder {
  const PreviewScannerBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['.showfase.json'],
  };

  @override
  Future<void> build(BuildStep step) async {
    final AssetId inputId = step.inputId;
    if (!await step.resolver.isLibrary(inputId)) return;

    final LibraryElement library = await step.inputLibrary;
    final List<PreviewMetadata> metas = scanForBuildStep(library, step);
    if (metas.isEmpty) return;

    final AssetId outputId = inputId.changeExtension('.showfase.json');
    await step.writeAsString(
      outputId,
      jsonEncode(metas.map((PreviewMetadata m) => m.toJson()).toList()),
    );
  }
}
