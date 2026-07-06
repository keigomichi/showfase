import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'showfase_preview.dart';

/// Renders a single [ShowfasePreview] with all the environment overrides that
/// its `Preview` metadata specifies, plus any runtime overrides supplied by
/// the browser (theme toggle, text-scale slider, RTL toggle, locale picker).
///
/// The layering, from innermost to outermost:
///
///   1. `preview.builder()`
///   2. `previewData.wrapper` (if any)
///   3. `Theme` / `CupertinoTheme` (from `previewData.theme` +
///      `brightnessOverride` ?? `previewData.brightness`)
///   4. `Localizations` (from `previewData.localizations` + `localeOverride`)
///   5. `MediaQuery` (`textScaler` from `textScaleFactorOverride` ??
///      `previewData.textScaleFactor`)
///   6. `Directionality` (`textDirectionOverride`)
///   7. size constraints (`previewData.size`)
class ShowfasePreviewCanvas extends StatelessWidget {
  const ShowfasePreviewCanvas({
    super.key,
    required this.preview,
    this.brightnessOverride,
    this.textScaleFactorOverride,
    this.textDirectionOverride,
    this.localeOverride,
  });

  final ShowfasePreview preview;
  final Brightness? brightnessOverride;
  final double? textScaleFactorOverride;
  final TextDirection? textDirectionOverride;
  final Locale? localeOverride;

  @override
  Widget build(BuildContext context) {
    final Preview data = preview.previewData;

    Widget child = Builder(builder: (BuildContext _) => preview.builder());

    // Wrapper (applied around the raw widget).
    final Widget Function(Widget)? wrapper = data.wrapper;
    if (wrapper != null) {
      child = wrapper(child);
    }

    // Theme.
    final Brightness effectiveBrightness =
        brightnessOverride ??
        data.brightness ??
        MediaQuery.platformBrightnessOf(context);
    child = _applyTheme(context, data, effectiveBrightness, child);

    // Localizations.
    child = _applyLocalizations(data, localeOverride, child);

    // MediaQuery — text scale factor.
    final double? scaleFactor = textScaleFactorOverride ?? data.textScaleFactor;
    if (scaleFactor != null) {
      child = MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scaleFactor)),
        child: child,
      );
    }

    // Directionality.
    final TextDirection? dir = textDirectionOverride;
    if (dir != null) {
      child = Directionality(textDirection: dir, child: child);
    }

    // Size constraints.
    final Size? size = data.size;
    if (size != null) {
      child = _applySize(size, child);
    }

    return child;
  }

  Widget _applyTheme(
    BuildContext context,
    Preview data,
    Brightness brightness,
    Widget child,
  ) {
    final PreviewThemeData? themeData = data.theme?.call();
    if (themeData == null) return child;
    final (ThemeData? material, CupertinoThemeData? cupertino) = themeData
        .themeForBrightness(brightness);
    if (material != null) {
      child = Theme(data: material, child: child);
    }
    if (cupertino != null) {
      child = CupertinoTheme(data: cupertino, child: child);
    }
    return child;
  }

  Widget _applyLocalizations(Preview data, Locale? override, Widget child) {
    final PreviewLocalizationsData? loc = data.localizations?.call();
    if (loc == null && override == null) return child;
    final Locale locale =
        override ??
        loc?.locale ??
        (loc?.supportedLocales.first ?? const Locale('en', 'US'));
    final Iterable<LocalizationsDelegate<Object?>> delegates =
        <LocalizationsDelegate<Object?>>[
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          ...?loc?.localizationsDelegates,
        ];
    return Localizations(
      locale: locale,
      delegates: delegates.toList(growable: false),
      child: child,
    );
  }

  Widget _applySize(Size size, Widget child) {
    // A finite dimension imposes an exact constraint; `double.infinity` lets
    // the widget size itself in that dimension.
    double? w;
    double? h;
    if (size.width.isFinite) w = size.width;
    if (size.height.isFinite) h = size.height;
    if (w == null && h == null) return child;
    return Center(
      child: SizedBox(width: w, height: h, child: child),
    );
  }
}
