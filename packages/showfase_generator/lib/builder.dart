/// Entry point for `build.yaml` builder factories.
///
/// This file exists so `build_extensions` in `build.yaml` can name a single
/// import path for both phases of the showfase pipeline.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/preview_scanner_builder.dart';
import 'src/showfase_aggregator.dart';

/// Factory referenced by `build.yaml` for the phase-1 scanner.
Builder previewScannerBuilder(BuilderOptions options) =>
    const PreviewScannerBuilder();

/// Factory referenced by `build.yaml` for the phase-2 aggregator.
Builder showfaseBuilder(BuilderOptions options) =>
    LibraryBuilder(const ShowfaseAggregator(), generatedExtension: '.g.dart');
