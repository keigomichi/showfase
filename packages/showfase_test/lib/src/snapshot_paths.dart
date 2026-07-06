import 'package:showfase/showfase.dart';

/// The name a preview's snapshot file is derived from: the preview's `name`,
/// falling back to the function part of its id (everything after the first
/// `#`, e.g. `simpleButtonPreview` or `stackedPreview#1` for multi-previews).
String snapshotDisplayName(ShowfasePreview preview) {
  final String? name = preview.name;
  if (name != null && name.isNotEmpty) return name;
  final int hash = preview.id.indexOf('#');
  return hash >= 0 ? preview.id.substring(hash + 1) : preview.id;
}

final RegExp _invalidFileChars = RegExp(r'[/\\:*?"<>|\x00-\x1f]');

/// Replaces filesystem-unsafe characters with `_`, collapses runs of `_`,
/// and trims leading/trailing dots and spaces.
String sanitizeFileName(String segment) {
  final String cleaned = segment
      .replaceAll(_invalidFileChars, '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
  return cleaned.isEmpty ? '_' : cleaned;
}

/// Relative snapshot paths (`<group>/<name>`, no extension) for [previews],
/// index-aligned with the input.
///
/// Duplicate paths — stacked `@Preview`s without distinct names, or previews
/// in different libraries sharing a group and name — are disambiguated
/// deterministically by appending `_2`, `_3`, … in list order. Collisions are
/// reported through [onCollision] with the affected preview ids so users can
/// add distinguishing `name:`s.
List<String> resolveSnapshotPaths(
  List<ShowfasePreview> previews, {
  void Function(String path, List<String> previewIds)? onCollision,
}) {
  final Map<String, List<int>> byPath = <String, List<int>>{};
  final List<String> paths = <String>[
    for (final ShowfasePreview preview in previews)
      '${sanitizeFileName(preview.group)}/'
          '${sanitizeFileName(snapshotDisplayName(preview))}',
  ];
  for (int i = 0; i < paths.length; i++) {
    (byPath[paths[i]] ??= <int>[]).add(i);
  }
  final Set<String> used = byPath.keys.toSet();
  for (final MapEntry<String, List<int>> entry in byPath.entries) {
    final List<int> indexes = entry.value;
    if (indexes.length < 2) continue;
    onCollision?.call(entry.key, <String>[
      for (final int i in indexes) previews[i].id,
    ]);
    int suffix = 2;
    for (int n = 1; n < indexes.length; n++) {
      String candidate = '${entry.key}_$suffix';
      while (!used.add(candidate)) {
        suffix++;
        candidate = '${entry.key}_$suffix';
      }
      paths[indexes[n]] = candidate;
    }
  }
  return paths;
}
