import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// A simple info card.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Preview with a fixed width via `size`.
@Preview(name: 'Fixed width', group: 'Cards', size: Size(280, double.infinity))
Widget fixedWidthCard() => const InfoCard(
  title: 'Announcement',
  body: 'A message that spans multiple lines to demonstrate wrapping.',
);

/// Preview with an amplified text scale.
@Preview(name: 'Large text', group: 'Cards', textScaleFactor: 1.6)
Widget largeTextCard() => const InfoCard(
  title: 'Large text',
  body:
      'This preview forces text scale to 1.6× so it looks like a device '
      'with accessibility text sizing enabled.',
);

/// Preview forced to dark brightness.
@Preview(name: 'Dark mode', group: 'Cards', brightness: Brightness.dark)
Widget darkCard() => const InfoCard(
  title: 'Dark mode',
  body: 'Rendered under Brightness.dark by default.',
);
