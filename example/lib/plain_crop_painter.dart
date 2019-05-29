import 'dart:ui' as ui;
import 'package:image_crop/image_crop.dart';
import 'package:flutter/widgets.dart';

const _kCropOverlayActiveOpacity = 0.3;
const _kCropOverlayInactiveOpacity = 0.7;

class PlainCropPainter extends AbstractCropPainter {
  PlainCropPainter({
    CropPaintState state,
  }) : super(
      state: state);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.save();
    canvas.translate(rect.left, rect.top);

    final paint = Paint()..isAntiAlias = false;

    if (state.image != null) {
      final src = Rect.fromLTWH(
        0.0,
        0.0,
        state.image.width.toDouble(),
        state.image.height.toDouble(),
      );
      final dst = Rect.fromLTWH(
        rect.width * state.area.left - state.image.width * state.view.left * state.scale * state.ratio,
        rect.height * state.area.top - state.image.height * state.view.top * state.scale * state.ratio,
        state.image.width * state.scale * state.ratio,
        state.image.height * state.scale * state.ratio,
      );

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0.0, 0.0, rect.width, rect.height));
      canvas.drawImageRect(state.image, src, dst, paint);
      canvas.restore();
    }

    paint.color = Color.fromRGBO(
        0x0,
        0x0,
        0x0,
        _kCropOverlayActiveOpacity * state.active +
            _kCropOverlayInactiveOpacity * (1.0 - state.active));
    final boundaries = Rect.fromLTWH(
      rect.width * state.area.left,
      rect.height * state.area.top,
      rect.width * state.area.width,
      rect.height * state.area.height,
    );
    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, rect.width, boundaries.top), paint);
    canvas.drawRect(
        Rect.fromLTRB(0.0, boundaries.bottom, rect.width, rect.height), paint);
    canvas.drawRect(
        Rect.fromLTRB(0.0, boundaries.top, boundaries.left, boundaries.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTRB(
            boundaries.right, boundaries.top, rect.width, boundaries.bottom),
        paint);

    canvas.restore();
  }
}
