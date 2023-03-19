import 'dart:io';
import 'dart:ui';

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

      void expectSnapshot(Image img) async {
        expect(img.width, target.width, reason: 'Wrong width');
        expect(img.height, target.height, reason: 'Wrong height');

        final result = await img.toByteData(format: ImageByteFormat.png).then(
              (data) => data!.buffer.asUint8List(),
            );

        final expected =
            await File('./test/crop-expected_100x150.png').readAsBytes();

        expect(result, expected);
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

      await ctrl.crop();
    },
  );
}
