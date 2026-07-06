import 'package:flutter/widgets.dart';

/// Safe-area insets for both orientations of a [SnapshotDevice].
class SafeAreaInsets {
  /// Creates safe-area insets; both orientations default to zero.
  const SafeAreaInsets({
    this.portrait = EdgeInsets.zero,
    this.landscape = EdgeInsets.zero,
  });

  /// Insets applied when the device is in portrait orientation.
  final EdgeInsets portrait;

  /// Insets applied when the device is in landscape orientation.
  final EdgeInsets landscape;
}

/// Orientation of a [SnapshotDevice].
enum SnapshotDeviceOrientation {
  /// Taller than wide; the device's natural size.
  portrait,

  /// Wider than tall; the natural size flipped.
  landscape,
}

/// A device configuration that snapshots are rendered against.
///
/// [size] and [safeAreaInsets] follow [orientation], so a landscape variant
/// is just `device.copyWith(orientation: SnapshotDeviceOrientation.landscape)`.
class SnapshotDevice {
  /// Creates a device configuration.
  const SnapshotDevice({
    required this.name,
    required Size size,
    SafeAreaInsets safeAreaInsets = const SafeAreaInsets(),
    this.textScaler,
    this.pixelRatio = 1,
    this.orientation = SnapshotDeviceOrientation.portrait,
    this.brightness = Brightness.light,
    required this.platform,
  }) : _size = size,
       _safeAreaInsets = safeAreaInsets;

  /// Directory name the device's snapshots are written under.
  final String name;

  final Size _size;
  final SafeAreaInsets _safeAreaInsets;

  /// Text scaler applied through `MediaQuery`, or `null` to leave the
  /// ambient value untouched.
  final TextScaler? textScaler;

  /// Device pixel ratio. The default of 1 keeps golden PNGs sized in
  /// logical pixels.
  final double pixelRatio;

  /// Orientation; flips [size] and selects [safeAreaInsets].
  final SnapshotDeviceOrientation orientation;

  /// Platform brightness exposed through `MediaQuery`. A preview's own
  /// `@Preview(brightness: ...)` takes precedence, matching the browser.
  final Brightness brightness;

  /// Value assigned to `debugDefaultTargetPlatformOverride` while the
  /// device's snapshots are taken.
  final TargetPlatform platform;

  /// Logical size in the current [orientation].
  Size get size {
    return switch (orientation) {
      SnapshotDeviceOrientation.portrait => _size,
      SnapshotDeviceOrientation.landscape => _size.flipped,
    };
  }

  /// Safe-area insets for the current [orientation].
  EdgeInsets get safeAreaInsets {
    return switch (orientation) {
      SnapshotDeviceOrientation.portrait => _safeAreaInsets.portrait,
      SnapshotDeviceOrientation.landscape => _safeAreaInsets.landscape,
    };
  }

  /// Returns a copy with the given fields replaced.
  SnapshotDevice copyWith({
    String? name,
    Size? size,
    SafeAreaInsets? safeAreaInsets,
    TextScaler? textScaler,
    double? pixelRatio,
    SnapshotDeviceOrientation? orientation,
    Brightness? brightness,
    TargetPlatform? platform,
  }) {
    return SnapshotDevice(
      name: name ?? this.name,
      size: size ?? _size,
      safeAreaInsets: safeAreaInsets ?? _safeAreaInsets,
      textScaler: textScaler ?? this.textScaler,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      orientation: orientation ?? this.orientation,
      brightness: brightness ?? this.brightness,
      platform: platform ?? this.platform,
    );
  }

  /// iPhone SE (2nd generation), 375×667.
  static const SnapshotDevice iPhoneSE2nd = SnapshotDevice(
    name: 'iPhoneSE2nd',
    size: Size(375, 667),
    safeAreaInsets: SafeAreaInsets(portrait: EdgeInsets.fromLTRB(0, 20, 0, 0)),
    platform: TargetPlatform.iOS,
  );

  /// iPhone 15, 393×852.
  static const SnapshotDevice iPhone15 = SnapshotDevice(
    name: 'iPhone15',
    size: Size(393, 852),
    safeAreaInsets: SafeAreaInsets(
      portrait: EdgeInsets.fromLTRB(0, 59, 0, 34),
      landscape: EdgeInsets.fromLTRB(59, 0, 59, 21),
    ),
    platform: TargetPlatform.iOS,
  );

  /// Pixel 6, 411×914.
  static const SnapshotDevice pixel6 = SnapshotDevice(
    name: 'pixel6',
    size: Size(411, 914),
    safeAreaInsets: SafeAreaInsets(
      portrait: EdgeInsets.fromLTRB(0, 24, 0, 0),
      landscape: EdgeInsets.fromLTRB(0, 24, 0, 0),
    ),
    platform: TargetPlatform.android,
  );
}
