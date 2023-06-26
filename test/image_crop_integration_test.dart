import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_crop/image_crop.dart';

import './image_crop_utils.dart';

void main() async {
  test(
    'on done receives image cropped to target size',
    tags: ['slow'],
    () async {
      const vp = Rect.fromLTWH(0, 0, 300, 400);
      const target = TargetSize(100, 150);

      void expectSnapshot(MemoryImage img) async {
        final expected =
            await File('./test/crop-expected_100x150.png').readAsBytes();

        expect(img.bytes, expected);
      }

      TestWidgetsFlutterBinding.ensureInitialized();
      final ctrl = await resolvedCtrl(
        image: FileImage(File('./test/crop-source_300x400.jpg')),
        target: target,
        onDone: expectSnapshot,
      );

      scaleImageBy(ctrl, vp, 2);
      increaseCropAreaBy(ctrl, 500);
      moveImageBy(ctrl, const Offset(100, 210));

      await ctrl.crop(1);
    },
  );
}
