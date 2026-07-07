# Unreleased

- Add `SnapshotShard` and `testShowfase(shard: ...)` for parallel VRT runs.
  Round-robin slicing over the deterministic preview order; golden paths
  (including collision suffixes) are resolved from the full list before
  slicing, so they never depend on the shard layout. One shard per test file
  parallelizes within a single `flutter test` run;
  `SnapshotShard.fromEnvironment()` reads `SHARD_INDEX` / `TOTAL_SHARDS`
  (env vars or `--dart-define`) for CI job matrices, and both axes compose.
- Speed up snapshot capture: the surface now starts at the preview's target
  size so fixed-size previews settle in a single pump instead of four, image
  precaching settles once per test instead of once per image, and only image
  decoding runs under `tester.runAsync` (pumps run in fake async). Recorded
  PNGs are byte-identical to 0.1.0.

# 0.1.0

- Initial release. `testShowfase` golden-test runner, `SnapshotDevice` presets,
  and automatic content-driven surface resizing.
