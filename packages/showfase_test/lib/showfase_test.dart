/// Golden (snapshot) testing for showfase catalogs.
///
/// Call [testShowfase] from a test file's `main` to register one golden test
/// per preview × device; run with `--update-goldens` to record baselines.
library;

export 'src/snapshot_device.dart';
export 'src/snapshot_shard.dart';
export 'src/test_showfase.dart';
