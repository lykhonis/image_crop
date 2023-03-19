import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'button.dart';
import 'const.dart';
import 'controller.dart';

class ImageCropper extends StatelessWidget {
  final CropController ctrl;

  const ImageCropper(this.ctrl, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Crop(ctrl),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: ConfirmButton(
              submit: ctrl.crop,
              state: ctrl.submitBtnState,
            ),
          ),
        ),
      ],
    );
  }
}

class Crop extends StatelessWidget {
  final CropController ctrl;

  const Crop(this.ctrl, {super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: ctrl.handleScaleStart,
        onScaleUpdate: ctrl.handleScaleUpdate,
        onScaleEnd: ctrl.handleScaleEnd,
        child: CropCanvas(ctrl),
      ),
    );
  }
}

class CropCanvas extends StatefulWidget {
  final CropController ctrl;

  const CropCanvas(this.ctrl);

  @override
  State<CropCanvas> createState() {
    return _CropCanvasState();
  }
}

class _CropCanvasState extends State<CropCanvas>
    with TickerProviderStateMixin, Drag {
  @override
  void initState() {
    super.initState();

    widget.ctrl.addListener(_redraw);
    widget.ctrl.activeAnimation = AnimationController(vsync: this)
      ..addListener(_redraw);
  }

  void _redraw() {
    setState(emptyFn);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_redraw);
    widget.ctrl.activeAnimation?.removeListener(_redraw);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    widget.ctrl.resolveImage(
      createLocalImageConfiguration(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CropPainter(widget.ctrl),
    );
  }
}

class CropPainter extends CustomPainter {
  final CropController ctrl;

  CropPainter(this.ctrl);

  @override
  bool shouldRepaint(CropPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final vp = ctrl.setViewport(size);

    final paint = Paint()..isAntiAlias = false;
    final active = ctrl.active;

    final image = ctrl.image;
    if (image != null) {
      final src = Rect.fromLTWH(
        0.0,
        0.0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      canvas.save();
      canvas.clipRect(vp);
      canvas.drawImageRect(image, src, ctrl.imageView, paint);
      canvas.restore();
    }

    paint.color = Color.fromRGBO(
        0x0,
        0x0,
        0x0,
        kCropOverlayActiveOpacity * active +
            kCropOverlayInactiveOpacity * (1.0 - active));

    final cropArea = ctrl.cropArea;
    if (cropArea.isEmpty == false) {
      canvas.save();
      canvas.clipRect(cropArea, clipOp: ui.ClipOp.difference);
      canvas.drawRect(vp, paint);
      canvas.restore();

      _drawGrid(canvas, cropArea, active);
      _drawHandles(canvas, cropArea);
    }
  }

  void _drawHandles(Canvas canvas, Rect boundaries) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = kCropHandleColor;

    canvas.drawOval(
      Rect.fromLTWH(
        boundaries.left - kCropHandleSize / 2,
        boundaries.top - kCropHandleSize / 2,
        kCropHandleSize,
        kCropHandleSize,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        boundaries.right - kCropHandleSize / 2,
        boundaries.bottom - kCropHandleSize / 2,
        kCropHandleSize,
        kCropHandleSize,
      ),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Rect cropArea, double active) {
    if (active == 0.0) {
      return;
    }

    final paint = Paint()
      ..isAntiAlias = false
      ..color = kCropGridColor.withOpacity(kCropGridColor.opacity * active)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(cropArea, paint);

    final columnWidth = cropArea.width / kCropGridColumnCount;
    for (var column = 1; column < kCropGridColumnCount; column++) {
      final x = cropArea.left + column * columnWidth;
      final p1 = Offset(x, cropArea.top);
      final p2 = Offset(x, cropArea.bottom);
      canvas.drawLine(p1, p2, paint);
    }

    final rowHeight = cropArea.height / kCropGridRowCount;
    for (var row = 1; row < kCropGridRowCount; row++) {
      final y = cropArea.top + row * rowHeight;
      final p1 = Offset(cropArea.left, y);
      final p2 = Offset(cropArea.right, y);
      canvas.drawLine(p1, p2, paint);
    }
  }
}
