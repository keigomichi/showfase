import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// A rounded primary button used throughout the example.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed ?? () {},
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label),
    );
  }

  /// A top-level constructor preview.
  @Preview(name: 'Constructor preview', group: 'Buttons')
  const PrimaryButton.preview({super.key})
    : label = 'Continue',
      onPressed = null;

  /// A factory preview producing a longer label.
  @Preview(name: 'Factory preview', group: 'Buttons')
  factory PrimaryButton.longLabel() =>
      const PrimaryButton(label: 'Save and continue');

  /// A static-method preview that returns a `Widget` directly.
  @Preview(name: 'Static preview', group: 'Buttons')
  static Widget previewDisabled() =>
      const PrimaryButton(label: 'Disabled', onPressed: null);
}

/// A top-level function returning `Widget` — the most common preview shape.
@Preview(name: 'Simple button', group: 'Buttons')
Widget simpleButtonPreview() => const PrimaryButton(label: 'Tap me');

/// A `WidgetBuilder`-returning preview.
@Preview(name: 'Builder-returning', group: 'Buttons')
WidgetBuilder builderButtonPreview() =>
    (BuildContext context) => PrimaryButton(
      label: 'Using ${Theme.of(context).brightness.name} theme',
    );
