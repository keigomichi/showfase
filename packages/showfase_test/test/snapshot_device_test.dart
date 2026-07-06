import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase_test/showfase_test.dart';

void main() {
  test('landscape flips the size and selects landscape insets', () {
    final device = SnapshotDevice.iPhone15.copyWith(
      orientation: SnapshotDeviceOrientation.landscape,
    );
    expect(device.size, const Size(852, 393));
    expect(device.safeAreaInsets, const EdgeInsets.fromLTRB(59, 0, 59, 21));
  });

  test('portrait uses the natural size and portrait insets', () {
    expect(SnapshotDevice.iPhone15.size, const Size(393, 852));
    expect(
      SnapshotDevice.iPhone15.safeAreaInsets,
      const EdgeInsets.fromLTRB(0, 59, 0, 34),
    );
  });

  test('copyWith preserves unspecified fields', () {
    const device = SnapshotDevice(
      name: 'custom',
      size: Size(100, 200),
      textScaler: TextScaler.linear(1.5),
      pixelRatio: 3,
      brightness: Brightness.dark,
      platform: TargetPlatform.android,
    );
    final renamed = device.copyWith(name: 'renamed');
    expect(renamed.textScaler, const TextScaler.linear(1.5));
    expect(renamed.pixelRatio, 3);
    expect(renamed.brightness, Brightness.dark);
    expect(renamed.platform, TargetPlatform.android);
    expect(renamed.size, const Size(100, 200));
  });

  test('brightness defaults to light', () {
    expect(SnapshotDevice.pixel6.brightness, Brightness.light);
  });
}
