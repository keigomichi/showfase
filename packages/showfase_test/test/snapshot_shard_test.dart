import 'package:flutter_test/flutter_test.dart';
import 'package:showfase_test/showfase_test.dart';

void main() {
  group('constructor', () {
    test('rejects a non-positive total', () {
      expect(() => SnapshotShard(index: 0, total: 0), throwsAssertionError);
    });

    test('rejects an index outside [0, total)', () {
      expect(() => SnapshotShard(index: -1, total: 2), throwsAssertionError);
      expect(() => SnapshotShard(index: 2, total: 2), throwsAssertionError);
    });

    test('accepts the single-shard identity', () {
      const shard = SnapshotShard(index: 0, total: 1);
      expect(shard.contains(0), isTrue);
      expect(shard.contains(41), isTrue);
    });
  });

  group('contains', () {
    test('selects every total-th preview starting at index', () {
      const shard = SnapshotShard(index: 1, total: 3);
      expect(
        [for (var i = 0; i < 7; i++) shard.contains(i)],
        [false, true, false, false, true, false, false],
      );
    });

    test('shards partition the preview indices', () {
      const total = 4;
      for (var i = 0; i < 100; i++) {
        final owners = [
          for (var s = 0; s < total; s++)
            if (SnapshotShard(index: s, total: total).contains(i)) s,
        ];
        expect(owners, hasLength(1), reason: 'index $i');
      }
    });
  });

  group('fromEnvironment', () {
    test('defaults to the full set when unset', () {
      final shard = SnapshotShard.fromEnvironment(environment: const {});
      expect(shard.index, 0);
      expect(shard.total, 1);
    });

    test('reads SHARD_INDEX and TOTAL_SHARDS', () {
      final shard = SnapshotShard.fromEnvironment(
        environment: const {'SHARD_INDEX': '2', 'TOTAL_SHARDS': '8'},
      );
      expect(shard.index, 2);
      expect(shard.total, 8);
    });

    test('defaults the missing half', () {
      final onlyTotal = SnapshotShard.fromEnvironment(
        environment: const {'TOTAL_SHARDS': '4'},
      );
      expect(onlyTotal.index, 0);
      expect(onlyTotal.total, 4);
    });

    test('treats an empty value as unset', () {
      final shard = SnapshotShard.fromEnvironment(
        environment: const {'SHARD_INDEX': '', 'TOTAL_SHARDS': ''},
      );
      expect(shard.index, 0);
      expect(shard.total, 1);
    });

    test('throws on a non-integer value instead of running a wrong subset', () {
      expect(
        () => SnapshotShard.fromEnvironment(
          environment: const {'TOTAL_SHARDS': 'four'},
        ),
        throwsArgumentError,
      );
    });

    test('throws on an out-of-range combination', () {
      expect(
        () => SnapshotShard.fromEnvironment(
          environment: const {'SHARD_INDEX': '4', 'TOTAL_SHARDS': '4'},
        ),
        throwsArgumentError,
      );
      expect(
        () => SnapshotShard.fromEnvironment(
          environment: const {'TOTAL_SHARDS': '0'},
        ),
        throwsArgumentError,
      );
    });
  });
}
