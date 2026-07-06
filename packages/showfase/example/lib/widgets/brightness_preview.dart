import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Custom multi-preview that emits `Light` and `Dark` variants.
final class BrightnessPreview extends MultiPreview {
  const BrightnessPreview();
  @override
  // ignore: avoid_field_initializers_in_const_classes
  final List<Preview> previews = const <Preview>[
    Preview(name: 'Light', brightness: Brightness.light, group: 'Themed'),
    Preview(name: 'Dark', brightness: Brightness.dark, group: 'Themed'),
  ];
}

@BrightnessPreview()
Widget themedTilePreview() => Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Themed tile'),
        subtitle: Builder(
          builder: (BuildContext context) => Text(
            'Rendered under ${Theme.of(context).brightness.name} theme.',
          ),
        ),
      ),
    );

@Preview(name: 'Stacked A', group: 'Themed', brightness: Brightness.light)
@Preview(name: 'Stacked B', group: 'Themed', brightness: Brightness.dark)
Widget stackedPreview() => const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Two @Preview annotations stacked on one function.'),
      ),
    );
