import 'package:flutter/material.dart';

import 'preview_detail_screen.dart';
import 'showfase_preview.dart';

/// The main browser widget for a showfase catalog.
///
/// Can be embedded inside an existing `MaterialApp`; for a standalone catalog
/// app use [ShowfaseApp] which wires up `MaterialApp` and light/dark themes.
class ShowfaseBrowser extends StatefulWidget {
  const ShowfaseBrowser({
    super.key,
    required this.previews,
    this.title = 'Showfase',
  });

  final List<ShowfasePreview> previews;
  final String title;

  @override
  State<ShowfaseBrowser> createState() => _ShowfaseBrowserState();
}

class _ShowfaseBrowserState extends State<ShowfaseBrowser> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShowfasePreview> get _filtered {
    if (_query.isEmpty) return widget.previews;
    final String q = _query.toLowerCase();
    return widget.previews
        .where((ShowfasePreview p) =>
            (p.name ?? '').toLowerCase().contains(q) ||
            p.group.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Map<String, List<ShowfasePreview>> get _grouped {
    final Map<String, List<ShowfasePreview>> map = <String, List<ShowfasePreview>>{};
    for (final ShowfasePreview p in _filtered) {
      map.putIfAbsent(p.group, () => <ShowfasePreview>[]).add(p);
    }
    // Stable alphabetical ordering.
    final List<String> keys = map.keys.toList()..sort();
    return <String, List<ShowfasePreview>>{
      for (final String k in keys) k: map[k]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ShowfasePreview>> groups = _grouped;
    final int totalCount = _filtered.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (String v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search previews',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      body: totalCount == 0
          ? const _EmptyState()
          : ListView(
              children: <Widget>[
                for (final MapEntry<String, List<ShowfasePreview>> entry in groups.entries)
                  _GroupSection(group: entry.key, previews: entry.value),
              ],
            ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.previews});
  final String group;
  final List<ShowfasePreview> previews;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            '$group  ·  ${previews.length}',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        for (final ShowfasePreview p in previews) _PreviewCard(preview: p),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final ShowfasePreview preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PreviewDetailScreen(preview: preview),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      preview.name ?? '(unnamed)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.id,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No matching previews.'),
      ),
    );
  }
}
