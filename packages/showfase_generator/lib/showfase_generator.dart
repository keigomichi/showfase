/// Public entry point for the showfase build_runner integration.
///
/// End users don't import this library directly — see `builder.dart` for the
/// builder factories referenced by `build.yaml`. It is exported for tests and
/// tooling that inspect the internal metadata model.
library;

export 'src/const_emitter.dart';
export 'src/const_encoder.dart';
export 'src/const_node.dart';
export 'src/preview_metadata.dart';
export 'src/preview_scanner.dart';
export 'src/preview_scanner_builder.dart';
export 'src/showfase_aggregator.dart';
