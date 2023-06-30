import 'package:flutter/widgets.dart';
import 'package:image_crop/image_crop.dart';
import 'package:test/test.dart';

import './image_crop_utils.dart';

void main() {
  const square = TargetSize.square(8);

  group('cropArea', () {
    test('centered on viewport', () {
      final ctrl = cropController();
      final vp = ctrl.setViewport(const Size(300, 600));
      expect(
        ctrl.cropArea,
        Rect.fromCenter(
          center: vp.center,
          width: 260,
          height: 260,
        ),
      );
    });

    group('respect aspect ratio', () {
      void runTest({
        required Size screen,
        required TargetSize targetSize,
        required Size expected,
      }) {
        final ctrl = cropController(
          target: targetSize,
        );
        final vp = ctrl.setViewport(screen);
        expect(
          ctrl.cropArea,
          Rect.fromCenter(
            center: vp.center,
            width: expected.width,
            height: expected.height,
          ),
        );
      }

      test('portrait screen, landscape ratio', () {
        runTest(
          targetSize: const TargetSize(16, 9),
          screen: const Size(300, 600),
          expected: const Size(260, 260 * 9 / 16),
        );
      });
      test('portrait screen, squared ratio', () {
        runTest(
          targetSize: square,
          screen: const Size(300, 600),
          expected: const Size(260, 260),
        );
      });
      test('portrait screen, portrait ratio', () {
        runTest(
          targetSize: const TargetSize(3, 4),
          screen: const Size(300, 600),
          expected: const Size(3 * 260 / 3, 4 * 260 / 3),
        );
      });
      test('squared screen, landscape ratio', () {
        runTest(
          targetSize: const TargetSize(16, 9),
          screen: const Size(600, 600),
          expected: const Size(560, 560 * 9 / 16),
        );
      });
      test('squared screen, squared ratio', () {
        runTest(
          targetSize: square,
          screen: const Size(600, 600),
          expected: const Size(560, 560),
        );
      });
      test('squared screen, portrait ratio', () {
        runTest(
          targetSize: const TargetSize(3, 6),
          screen: const Size(600, 600),
          expected: const Size(560 * 0.5, 560),
        );
      });
      test('landscape screen, landscape ratio', () {
        runTest(
          targetSize: const TargetSize(6, 5),
          screen: const Size(600, 200),
          expected: const Size(6 * 160 / 5, 5 * 160 / 5),
        );
      });
      test('landscape screen, squared ratio', () {
        runTest(
          targetSize: square,
          screen: const Size(600, 300),
          expected: const Size(260, 260),
        );
      });
      test('landscape screen, portrait ratio', () {
        runTest(
          targetSize: const TargetSize(3, 6),
          screen: const Size(600, 300),
          expected: const Size(260 * 3 / 6, 260),
        );
      });
    });

    group('hit top handle', () {
      test('move down decrease size', () {
        final ctrl = cropController();
        final vp = ctrl.setViewport(const Size(300, 600));
        ctrl.handleScaleStart(hitCropHandle(ctrl.cropArea, CropHandle.topLeft));
        ctrl.handleScaleUpdate(moveDownBy(10));
        expect(
          ctrl.cropArea,
          Rect.fromCenter(
            center: vp.center,
            width: 260 - 10 * 2,
            height: 260 - 10 * 2,
          ),
        );
      });
      test('move up increase size', () {
        final ctrl = cropController();
        final vp = ctrl.setViewport(const Size(300, 600));
        ctrl.handleScaleStart(hitCropHandle(ctrl.cropArea, CropHandle.topLeft));
        // size from 260 to 220
        ctrl.handleScaleUpdate(moveDownBy(20));
        // size from 220 to 240
        ctrl.handleScaleUpdate(moveUpBy(10));
        expect(
          ctrl.cropArea.toString(),
          Rect.fromCenter(
            center: vp.center,
            width: 220 + 10 * 2,
            height: 220 + 10 * 2,
          ).toString(),
        );
      });
    });

    group('hit bottom handle', () {
      test('move up decrease size', () {
        final ctrl = cropController();
        final vp = ctrl.setViewport(const Size(300, 600));
        ctrl.handleScaleStart(
          hitCropHandle(ctrl.cropArea, CropHandle.bottomRight),
        );
        ctrl.handleScaleUpdate(moveUpBy(10));
        expect(
          ctrl.cropArea,
          Rect.fromCenter(
            center: vp.center,
            width: 260 - 10 * 2,
            height: 260 - 10 * 2,
          ),
        );
      });
      test('move down increase size', () {
        final ctrl = cropController();
        final vp = ctrl.setViewport(const Size(300, 600));
        ctrl.handleScaleStart(
          hitCropHandle(ctrl.cropArea, CropHandle.bottomRight),
        );
        // size from 260 to 220
        ctrl.handleScaleUpdate(moveUpBy(20));
        // size from 220 to 240
        ctrl.handleScaleUpdate(moveDownBy(10));
        expect(
          ctrl.cropArea.toString(),
          Rect.fromCenter(
            center: vp.center,
            width: 220 + 10 * 2,
            height: 220 + 10 * 2,
          ).toString(),
        );
      });
    });

    test('limit size to viewport minus padding', () {
      final ctrl = cropController();
      final vp = ctrl.setViewport(const Size(300, 600));

      increaseCropAreaBy(ctrl, 300);

      expect(
        ctrl.cropArea,
        Rect.fromCenter(
          center: vp.center,
          width: 260,
          height: 260,
        ),
      );
    });

    test('limit size to minimum crop area size', () {
      final ctrl = cropController(
        target: const TargetSize(9, 3),
      );
      ctrl.setViewport(const Size(300, 600));

      // decrease to min
      decreaseCropAreaBy(ctrl, 600);
      expect(
        ctrl.cropArea.size,
        const Size(96, 32),
      );

      // increase by a tiny bit
      increaseCropAreaBy(ctrl, 32);
      expect(
        ctrl.cropArea.size,
        const Size(192, 64),
      );

      // increase to max
      increaseCropAreaBy(ctrl, 100);
      expect(
        ctrl.cropArea.size.aspectRatio,
        closeTo(3, 0.001),
      );
    });

    test('move image on crop resize', () async {
      const vp = Rect.fromLTWH(0, 0, 300, 400);
      final ctrl = await resolvedCtrl(vp: vp);

      decreaseCropAreaBy(ctrl, 50);
      moveImageToCropArea(ctrl, vp);
      increaseCropAreaBy(ctrl, 50);

      expect(
        ctrl.imageView.topLeft,
        ctrl.cropArea.topLeft,
      );
    });

    test('scale image on crop resize', () async {
      const vp = Rect.fromLTWH(0, 0, 300, 400);
      final ctrl = await resolvedCtrl(
        vp: vp,
        target: const TargetSize(400, 100),
      );

      decreaseCropAreaBy(ctrl, 150);
      scaleImageBy(ctrl, vp, 0.001);
      expect(ctrl.scale, closeTo(0.42, 0.01));

      increaseCropAreaBy(ctrl, 150);
      expect(ctrl.scale, closeTo(0.86, 0.01));
    });
  });

  group('image', () {
    test('fully cover even if too small', () async {
      final vp = const Rect.fromLTWH(0, 0, 600, 800);
      final ctrl = await resolvedCtrl(vp: vp);
      // double the current image size
      expect(ctrl.scale, 2);
    });

    test('center it on load', () async {
      final vp = const Rect.fromLTWH(0, 0, 120, 120);
      final ctrl = await resolvedCtrl(vp: vp);

      expect(
        ctrl.imageView,
        Rect.fromCenter(
          center: vp.center,
          width: 300 * 0.4,
          height: 400 * 0.4,
        ),
      );
    });

    group('move', () {
      test('move up', () async {
        final ctrl = await resolvedCtrl();
        final initial = ctrl.imageView;

        ctrl.handleScaleStart(moveStart(initial));
        ctrl.handleScaleUpdate(moveUpBy(10));

        expect(
          ctrl.imageView,
          initial.translate(0, -10),
        );
      });

      test('move down', () async {
        final ctrl = await resolvedCtrl();
        final initial = ctrl.imageView;

        ctrl.handleScaleStart(moveStart(initial));
        ctrl.handleScaleUpdate(moveDownBy(10));

        expect(
          ctrl.imageView,
          initial.translate(0, 10),
        );
      });

      test('prevent moving bottom-right edges inside cropArea', () async {
        final ctrl = await resolvedCtrl();
        final offset = ctrl.cropArea.bottomRight -
            ctrl.imageView.bottomRight -
            const Offset(10, 10);

        ctrl.handleScaleStart(moveStart(ctrl.imageView));
        ctrl.handleScaleUpdate(moveBy(offset));

        expect(
          ctrl.imageView.bottomRight,
          ctrl.cropArea.bottomRight,
        );
      });

      test('prevent moving top-left edges inside cropArea', () async {
        final ctrl = await resolvedCtrl();
        final offset = ctrl.cropArea.topLeft -
            ctrl.imageView.topLeft +
            const Offset(10, 10);

        ctrl.handleScaleStart(moveStart(ctrl.imageView));
        ctrl.handleScaleUpdate(moveBy(offset));

        expect(
          ctrl.imageView.topLeft,
          ctrl.cropArea.topLeft,
        );
      });
    });

    group('scale', () {
      test('on multiple events keep last', () async {
        const vp = Rect.fromLTWH(0, 0, 300, 400);
        final ctrl = await resolvedCtrl(vp: vp);

        /// Flutter will send the current scale delta between **initial event**
        /// and the update
        final initial = ctrl.imageView.size;
        ctrl.handleScaleStart(scaleStart(vp));
        ctrl.handleScaleUpdate(scaleBy(1.2));
        ctrl.handleScaleUpdate(scaleBy(1.5));
        ctrl.handleScaleUpdate(scaleBy(2));
        ctrl.handleScaleEnd(endEvent);

        expect(ctrl.imageView.size, initial * 2);
      });

      test('limited by maximumScale', () async {
        const vp = Rect.fromLTWH(0, 0, 300, 400);
        final ctrl = await resolvedCtrl(vp: vp, maximumScale: 3);

        final initial = ctrl.imageView.size;
        scaleImageBy(ctrl, vp, 5);

        expect(
          ctrl.imageView.size,
          initial * 3.0,
        );
      });

      test('override maximumScale to always cover the whole viewport',
          () async {
        const vp = Rect.fromLTWH(0, 0, 600, 400);
        final ctrl = await resolvedCtrl(vp: vp, maximumScale: 1);

        scaleImageBy(ctrl, vp, 5);

        expect(ctrl.scale, 2.0);
      });

      test('limited by crop area', () async {
        const vp = Rect.fromLTWH(0, 0, 300, 400);
        final ctrl = await resolvedCtrl(vp: vp);

        scaleImageBy(ctrl, vp, 0.001);

        expect(
          ctrl.imageView.width,
          ctrl.cropArea.width,
        );
        expect(
          (ctrl.imageView.size.aspectRatio).toStringAsFixed(2),
          (ctrl.image!.width / ctrl.image!.height).toStringAsFixed(2),
          reason: 'Resize due to crop area should keep image aspect ratio',
        );
      });
    });
  });
}
