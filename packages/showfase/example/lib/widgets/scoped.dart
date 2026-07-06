import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Simulates a scope that the widget being previewed depends on — e.g. a
/// theming wrapper, a mock repository provider, a `MediaQuery` override.
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.child});
  final Widget child;

  static Widget wrap(Widget child) => AppScope(child: child);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

/// Preview using a top-level static wrapper function.
@Preview(name: 'With wrapper', group: 'Scopes', wrapper: AppScope.wrap)
Widget wrappedPreview() => const Padding(
      padding: EdgeInsets.all(8),
      child: Text('This widget is wrapped by AppScope'),
    );
