import 'dart:io';

import 'package:flutter/foundation.dart';

/// A 1-of-N slice of the preview set, for running VRT in parallel.
///
/// Pass to `testShowfase(shard: ...)` to register only every [total]-th
/// preview starting at [index] (round-robin, so mixed workloads stay
/// balanced across shards). Golden file paths do not depend on the shard
/// configuration: all shards together produce exactly the files an unsharded
/// run would, so an external diff tool sees a stable baseline layout.
///
/// Two independent axes of parallelism compose by index arithmetic:
///
/// * **Across CI jobs** — one job per shard, selected via
///   [SnapshotShard.fromEnvironment].
/// * **Within one `flutter test` run** — one test file per shard;
///   `flutter test` executes suites concurrently, using every core of the
///   machine.
///
/// For both at once (J jobs × K files per job), give file `k` of job `j`
/// `SnapshotShard(index: j * K + k, total: J * K)`.
@immutable
class SnapshotShard {
  const SnapshotShard({required this.index, required this.total})
    : assert(total >= 1, 'total must be at least 1'),
      assert(
        0 <= index && index < total,
        'index must be in [0, total), got $index of $total',
      );

  /// Reads the shard from `SHARD_INDEX` / `TOTAL_SHARDS`, checking process
  /// environment variables first and `--dart-define` second.
  ///
  /// Unset values default to index 0 / total 1, so the same test file runs
  /// the full set locally and a slice under a sharded CI matrix. A set but
  /// non-integer value throws [ArgumentError] rather than silently running
  /// the wrong subset.
  ///
  /// [environment] overrides the process environment lookup (for tests).
  factory SnapshotShard.fromEnvironment({Map<String, String>? environment}) {
    final Map<String, String> env = environment ?? Platform.environment;
    final int index =
        _parse(env['SHARD_INDEX'], 'SHARD_INDEX') ??
        _parse(
          const String.fromEnvironment('SHARD_INDEX'),
          'SHARD_INDEX (dart-define)',
        ) ??
        0;
    final int total =
        _parse(env['TOTAL_SHARDS'], 'TOTAL_SHARDS') ??
        _parse(
          const String.fromEnvironment('TOTAL_SHARDS'),
          'TOTAL_SHARDS (dart-define)',
        ) ??
        1;
    if (total < 1) {
      throw ArgumentError('TOTAL_SHARDS must be at least 1, got $total');
    }
    if (index < 0 || index >= total) {
      throw ArgumentError(
        'SHARD_INDEX must be in [0, TOTAL_SHARDS), got $index of $total',
      );
    }
    return SnapshotShard(index: index, total: total);
  }

  /// 0-based position of this shard.
  final int index;

  /// Number of shards the preview set is split into.
  final int total;

  /// Whether the preview at [previewIndex] (within the filtered, deterministic
  /// preview order) belongs to this shard.
  bool contains(int previewIndex) => previewIndex % total == index;

  @override
  String toString() => 'SnapshotShard($index of $total)';

  static int? _parse(String? value, String name) {
    if (value == null || value.isEmpty) return null;
    final int? parsed = int.tryParse(value);
    if (parsed == null) {
      throw ArgumentError('$name must be an integer, got "$value"');
    }
    return parsed;
  }
}
