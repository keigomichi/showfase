@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showfase_example/showfase.g.dart';
import 'package:showfase_test/showfase_test.dart';

Future<void> main() async {
  await testShowfase(
    showfasePreviews(),
    devices: [SnapshotDevice.iPhone15],
    builder: (preview, device) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: preview),
    ),
  );
}
