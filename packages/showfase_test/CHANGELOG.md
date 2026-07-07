# Unreleased

- Speed up snapshot capture: the surface now starts at the preview's target
  size so fixed-size previews settle in a single pump instead of four, image
  precaching settles once per test instead of once per image, and only image
  decoding runs under `tester.runAsync` (pumps run in fake async). Recorded
  PNGs are byte-identical to 0.1.0.

# 0.1.0

- Initial release. `testShowfase` golden-test runner, `SnapshotDevice` presets,
  and automatic content-driven surface resizing.
