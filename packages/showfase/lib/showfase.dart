/// Runtime for the showfase UI catalog.
///
/// Import this library from the file annotated with `@ShowfaseRoot()` and pass
/// the generated `showfasePreviews()` function's result to [ShowfaseApp].
library;

export 'package:flutter/widget_previews.dart'
    show MultiPreview, Preview, PreviewLocalizationsData, PreviewThemeData;

export 'src/build_helpers.dart'
    show buildShowfaseMultiPreview, buildShowfasePreview;
export 'src/preview_canvas.dart' show ShowfasePreviewCanvas;
export 'src/preview_detail_screen.dart' show PreviewDetailScreen;
export 'src/showfase_app.dart' show ShowfaseApp;
export 'src/showfase_browser.dart' show ShowfaseBrowser;
export 'src/showfase_preview.dart' show ShowfasePreview;
