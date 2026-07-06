// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: ShowfaseAggregator
// **************************************************************************

// ignore_for_file: implementation_imports, type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:showfase/showfase.dart' as _i1;
import 'package:showfase_example/widgets/brightness_preview.dart' as _i2;
import 'package:flutter/src/widget_previews/widget_previews.dart' as _i3;
import 'dart:ui' as _i4;
import 'package:showfase_example/widgets/buttons.dart' as _i5;
import 'package:showfase_example/widgets/cards.dart' as _i6;
import 'package:showfase_example/widgets/scoped.dart' as _i7;

List<_i1.ShowfasePreview> showfasePreviews() => [
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/brightness_preview.dart#stackedPreview',
    scriptUri: 'package:showfase_example/widgets/brightness_preview.dart',
    previewFunction: () => _i2.stackedPreview(),
    transformedPreview: const _i3.Preview(
      name: 'Stacked A',
      group: 'Themed',
      brightness: _i4.Brightness.light,
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/brightness_preview.dart#stackedPreview',
    scriptUri: 'package:showfase_example/widgets/brightness_preview.dart',
    previewFunction: () => _i2.stackedPreview(),
    transformedPreview: const _i3.Preview(
      name: 'Stacked B',
      group: 'Themed',
      brightness: _i4.Brightness.dark,
    ).transform(),
  ),
  ..._i1.buildShowfaseMultiPreview(
    id: 'package:showfase_example/widgets/brightness_preview.dart#themedTilePreview',
    scriptUri: 'package:showfase_example/widgets/brightness_preview.dart',
    previewFunction: () => _i2.themedTilePreview(),
    multiPreview: const _i2.BrightnessPreview(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/buttons.dart#PrimaryButton.longLabel',
    scriptUri: 'package:showfase_example/widgets/buttons.dart',
    previewFunction: () => _i5.PrimaryButton.longLabel(),
    transformedPreview: const _i3.Preview(
      name: 'Factory preview',
      group: 'Buttons',
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/buttons.dart#PrimaryButton.preview',
    scriptUri: 'package:showfase_example/widgets/buttons.dart',
    previewFunction: () => _i5.PrimaryButton.preview(),
    transformedPreview: const _i3.Preview(
      name: 'Constructor preview',
      group: 'Buttons',
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/buttons.dart#PrimaryButton.previewDisabled',
    scriptUri: 'package:showfase_example/widgets/buttons.dart',
    previewFunction: () => _i5.PrimaryButton.previewDisabled(),
    transformedPreview: const _i3.Preview(
      name: 'Static preview',
      group: 'Buttons',
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/buttons.dart#builderButtonPreview',
    scriptUri: 'package:showfase_example/widgets/buttons.dart',
    previewFunction: () => _i5.builderButtonPreview(),
    transformedPreview: const _i3.Preview(
      name: 'Builder-returning',
      group: 'Buttons',
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/buttons.dart#simpleButtonPreview',
    scriptUri: 'package:showfase_example/widgets/buttons.dart',
    previewFunction: () => _i5.simpleButtonPreview(),
    transformedPreview: const _i3.Preview(
      name: 'Simple button',
      group: 'Buttons',
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/cards.dart#darkCard',
    scriptUri: 'package:showfase_example/widgets/cards.dart',
    previewFunction: () => _i6.darkCard(),
    transformedPreview: const _i3.Preview(
      name: 'Dark mode',
      group: 'Cards',
      brightness: _i4.Brightness.dark,
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/cards.dart#fixedWidthCard',
    scriptUri: 'package:showfase_example/widgets/cards.dart',
    previewFunction: () => _i6.fixedWidthCard(),
    transformedPreview: const _i3.Preview(
      name: 'Fixed width',
      group: 'Cards',
      size: _i4.Size(280.0, double.infinity),
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/cards.dart#largeTextCard',
    scriptUri: 'package:showfase_example/widgets/cards.dart',
    previewFunction: () => _i6.largeTextCard(),
    transformedPreview: const _i3.Preview(
      name: 'Large text',
      group: 'Cards',
      textScaleFactor: 1.6,
    ).transform(),
  ),
  _i1.buildShowfasePreview(
    id: 'package:showfase_example/widgets/scoped.dart#wrappedPreview',
    scriptUri: 'package:showfase_example/widgets/scoped.dart',
    previewFunction: () => _i7.wrappedPreview(),
    transformedPreview: const _i3.Preview(
      name: 'With wrapper',
      group: 'Scopes',
      wrapper: _i7.AppScope.wrap,
    ).transform(),
  ),
];
