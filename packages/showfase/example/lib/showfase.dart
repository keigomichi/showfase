import 'package:flutter/material.dart';
import 'package:showfase/showfase.dart';
import 'package:showfase_annotation/showfase_annotation.dart';

import 'showfase.g.dart';
// The following imports pull in the previews so that the code generator
// discovers them during the build.
// ignore: unused_import
import 'widgets/brightness_preview.dart';
// ignore: unused_import
import 'widgets/buttons.dart';
// ignore: unused_import
import 'widgets/cards.dart';
// ignore: unused_import
import 'widgets/scoped.dart';

@ShowfaseRoot()
void main() => runApp(
  ShowfaseApp(title: 'showfase example', previews: showfasePreviews()),
);
