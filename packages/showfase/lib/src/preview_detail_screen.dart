import 'package:flutter/material.dart';

import 'preview_canvas.dart';
import 'showfase_preview.dart';

/// The detail screen for a single preview.
///
/// Renders the preview inside a [ShowfasePreviewCanvas] and exposes a control
/// panel to switch brightness, text-scale, RTL, and locale at runtime.
class PreviewDetailScreen extends StatefulWidget {
  const PreviewDetailScreen({super.key, required this.preview});

  final ShowfasePreview preview;

  @override
  State<PreviewDetailScreen> createState() => _PreviewDetailScreenState();
}

enum _BrightnessMode { system, light, dark }

class _PreviewDetailScreenState extends State<PreviewDetailScreen> {
  _BrightnessMode _brightnessMode = _BrightnessMode.system;
  double _textScale = 1.0;
  bool _rtl = false;

  @override
  void initState() {
    super.initState();
    _textScale = widget.preview.previewData.textScaleFactor ?? 1.0;
    switch (widget.preview.previewData.brightness) {
      case Brightness.light:
        _brightnessMode = _BrightnessMode.light;
      case Brightness.dark:
        _brightnessMode = _BrightnessMode.dark;
      case null:
        _brightnessMode = _BrightnessMode.system;
    }
  }

  Brightness? _resolvedBrightness(BuildContext context) => switch (_brightnessMode) {
        _BrightnessMode.system => null,
        _BrightnessMode.light => Brightness.light,
        _BrightnessMode.dark => Brightness.dark,
      };

  @override
  Widget build(BuildContext context) {
    final ShowfasePreview p = widget.preview;
    return Scaffold(
      appBar: AppBar(title: Text(p.name ?? '(unnamed)')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 720;
          final Widget canvas = _CanvasFrame(
            child: ShowfasePreviewCanvas(
              preview: p,
              brightnessOverride: _resolvedBrightness(context),
              textScaleFactorOverride: _textScale,
              textDirectionOverride: _rtl ? TextDirection.rtl : null,
            ),
          );
          final Widget controls = _Controls(
            brightnessMode: _brightnessMode,
            onBrightnessMode: (m) => setState(() => _brightnessMode = m),
            textScale: _textScale,
            onTextScale: (s) => setState(() => _textScale = s),
            rtl: _rtl,
            onRtl: (v) => setState(() => _rtl = v),
            metadata: _MetadataPanel(preview: p),
          );
          if (wide) {
            return Row(
              children: <Widget>[
                Expanded(child: canvas),
                SizedBox(width: 320, child: controls),
              ],
            );
          }
          return Column(
            children: <Widget>[
              Expanded(child: canvas),
              const Divider(height: 1),
              SizedBox(height: 220, child: controls),
            ],
          );
        },
      ),
    );
  }
}

class _CanvasFrame extends StatelessWidget {
  const _CanvasFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.brightnessMode,
    required this.onBrightnessMode,
    required this.textScale,
    required this.onTextScale,
    required this.rtl,
    required this.onRtl,
    required this.metadata,
  });

  final _BrightnessMode brightnessMode;
  final ValueChanged<_BrightnessMode> onBrightnessMode;
  final double textScale;
  final ValueChanged<double> onTextScale;
  final bool rtl;
  final ValueChanged<bool> onRtl;
  final Widget metadata;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Brightness', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SegmentedButton<_BrightnessMode>(
            segments: const <ButtonSegment<_BrightnessMode>>[
              ButtonSegment(value: _BrightnessMode.system, label: Text('System')),
              ButtonSegment(value: _BrightnessMode.light, label: Text('Light')),
              ButtonSegment(value: _BrightnessMode.dark, label: Text('Dark')),
            ],
            selected: <_BrightnessMode>{brightnessMode},
            onSelectionChanged: (Set<_BrightnessMode> s) => onBrightnessMode(s.first),
          ),
          const SizedBox(height: 16),
          Text(
            'Text scale: ${textScale.toStringAsFixed(2)}×',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: textScale,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            label: '${textScale.toStringAsFixed(2)}×',
            onChanged: onTextScale,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Right-to-left'),
            value: rtl,
            onChanged: onRtl,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          metadata,
        ],
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({required this.preview});
  final ShowfasePreview preview;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Metadata', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text('id: ${preview.id}', style: style),
        Text('group: ${preview.group}', style: style),
        if (preview.previewData.size != null)
          Text('size: ${preview.previewData.size}', style: style),
        if (preview.scriptUri != null)
          Text(
            'source: ${preview.scriptUri}'
            '${preview.line != null ? ':${preview.line}' : ''}',
            style: style,
          ),
      ],
    );
  }
}
