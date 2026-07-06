import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_test/src/snapshot_paths.dart';

Widget _box() => const SizedBox();

ShowfasePreview _preview(String id, {String? name, String group = 'Default'}) {
  return ShowfasePreview(
    id: id,
    previewData: Preview(name: name, group: group),
    builder: _box,
  );
}

void main() {
  group('snapshotDisplayName', () {
    test('uses the preview name when set', () {
      expect(
        snapshotDisplayName(_preview('pkg:a/a.dart#fn', name: 'Primary')),
        'Primary',
      );
    });

    test('falls back to the id fragment after the first #', () {
      expect(snapshotDisplayName(_preview('pkg:a/a.dart#fn')), 'fn');
    });

    test('keeps the multi-preview index in the fallback', () {
      expect(snapshotDisplayName(_preview('pkg:a/a.dart#fn#1')), 'fn#1');
    });

    test('treats an empty name as unset', () {
      expect(snapshotDisplayName(_preview('pkg:a/a.dart#fn', name: '')), 'fn');
    });
  });

  group('sanitizeFileName', () {
    test('replaces filesystem-unsafe characters', () {
      expect(sanitizeFileName(r'a/b\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
    });

    test('collapses runs of underscores', () {
      expect(sanitizeFileName('a//b'), 'a_b');
    });

    test('trims leading and trailing dots and spaces', () {
      expect(sanitizeFileName(' .name. '), 'name');
    });

    test('keeps spaces and unicode inside the name', () {
      expect(sanitizeFileName('ボタン 一覧'), 'ボタン 一覧');
    });

    test('never returns an empty segment', () {
      expect(sanitizeFileName('..'), '_');
    });
  });

  group('resolveSnapshotPaths', () {
    test('builds group/name paths aligned with the input', () {
      final paths = resolveSnapshotPaths([
        _preview('a#one', name: 'One', group: 'Buttons'),
        _preview('a#two', name: 'Two', group: 'Cards'),
      ]);
      expect(paths, ['Buttons/One', 'Cards/Two']);
    });

    test('suffixes duplicates deterministically and reports them', () {
      final collisions = <String, List<String>>{};
      final paths = resolveSnapshotPaths([
        _preview('a#stacked'),
        _preview('a#stacked'),
        _preview('a#stacked'),
      ], onCollision: (path, ids) => collisions[path] = ids);
      expect(paths, [
        'Default/stacked',
        'Default/stacked_2',
        'Default/stacked_3',
      ]);
      expect(collisions, {
        'Default/stacked': ['a#stacked', 'a#stacked', 'a#stacked'],
      });
    });

    test('skips suffixes already taken by another preview', () {
      final paths = resolveSnapshotPaths([
        _preview('a#x', name: 'x'),
        _preview('a#y', name: 'x'),
        _preview('a#z', name: 'x_2'),
      ]);
      expect(paths, ['Default/x', 'Default/x_3', 'Default/x_2']);
    });

    test('does not report unique paths', () {
      var called = false;
      resolveSnapshotPaths([
        _preview('a#one', name: 'One'),
      ], onCollision: (_, _) => called = true);
      expect(called, isFalse);
    });
  });
}
