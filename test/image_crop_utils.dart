import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:image_crop/image_crop.dart';
import 'package:test/expect.dart';

final defaultImage = _TestImageProvider(width: 300, height: 400);

CropController cropController({
  ImageProvider? image,
  TargetSize target = const TargetSize.square(128),
  double maximumScale = 2.0,
  OnCropDone? onDone,
  OnCropError? onError,
}) {
  return CropController(
    maximumScale: maximumScale,
    imageProvider: image ?? defaultImage,
    target: target,
    onError: onError ??
        (err) {
          fail(err.toString());
        },
    onDone: onDone ?? (_) {},
  );
}

final endEvent = ScaleEndDetails();

void scaleImageBy(CropController ctrl, Rect vp, double scale) {
  ctrl.handleScaleStart(scaleStart(vp));
  ctrl.handleScaleUpdate(scaleBy(scale));
  ctrl.handleScaleEnd(endEvent);
}

ScaleUpdateDetails scaleBy(double scale) {
  return ScaleUpdateDetails(
    pointerCount: 2,
    scale: scale,
  );
}

void moveImageToCropArea(CropController ctrl, Rect vp) {
  final offset = ctrl.cropArea.topLeft - ctrl.imageView.topLeft;
  ctrl.handleScaleStart(moveStart(vp));
  ctrl.handleScaleUpdate(moveBy(offset));
  ctrl.handleScaleEnd(endEvent);
}

void decreaseCropAreaBy(CropController ctrl, int size) =>
    increaseCropAreaBy(ctrl, -size);

void increaseCropAreaBy(CropController ctrl, int size) {
  ctrl.handleScaleStart(hitCropHandle(ctrl.cropArea, CropHandle.bottomRight));
  ctrl.handleScaleUpdate(moveDownBy(size / 2));
  ctrl.handleScaleEnd(endEvent);
}

Future<CropController> resolvedCtrl({
  Rect? vp,
  double maximumScale = 2,
  TargetSize target = const TargetSize.square(128),
  ImageProvider? image,
  OnCropDone? onDone,
}) async {
  final completer = Completer<void>();
  void complete() {
    completer.complete();
  }

  final ctrl = cropController(
    image: image,
    target: target,
    maximumScale: maximumScale,
    onDone: onDone,
    onError: (e) {
      completer.completeError(e, e.causeTrace);
    },
  );
  vp ??= const Rect.fromLTWH(0, 0, 300, 400);

  ctrl.addListener(complete);
  ctrl.resolveImage(const ImageConfiguration());
  await completer.future;
  ctrl.removeListener(complete);

  ctrl.setViewport(vp.size);

  return ctrl;
}

void moveImageBy(CropController ctrl, Offset offset) {
  ctrl.handleScaleStart(moveStart(ctrl.cropArea));
  ctrl.handleScaleUpdate(moveBy(offset));
  ctrl.handleScaleEnd(endEvent);
}

ScaleUpdateDetails moveUpBy(double dy) => moveBy(Offset(0, -dy));

ScaleUpdateDetails moveDownBy(double dy) => moveBy(Offset(0, dy));

ScaleUpdateDetails moveBy(Offset delta) {
  return ScaleUpdateDetails(
    pointerCount: 1,
    focalPointDelta: delta,
  );
}

ScaleStartDetails moveStart(Rect r) {
  return ScaleStartDetails(
    pointerCount: 1,
    localFocalPoint: r.center,
  );
}

ScaleStartDetails scaleStart(Rect r) {
  return ScaleStartDetails(
    pointerCount: 2,
    localFocalPoint: r.center,
  );
}

ScaleStartDetails hitCropHandle(Rect cropArea, CropHandle h) {
  final Offset point;
  switch (h) {
    case CropHandle.topLeft:
      point = cropArea.topLeft;
      break;
    case CropHandle.bottomRight:
      point = cropArea.bottomRight;
      break;
  }
  return ScaleStartDetails(
    pointerCount: 1,
    focalPoint: point,
    localFocalPoint: point,
  );
}

class _TestImage implements ui.Image {
  @override
  final int width;
  @override
  final int height;

  _TestImage(this.width, this.height);

  @override
  ui.Image clone() => _TestImage(width, height);

  @override
  bool get debugDisposed => false;

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => [];

  @override
  void dispose() {}

  @override
  bool isCloneOf(ui.Image other) => false;

  @override
  Future<ByteData?> toByteData({
    ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
  }) async =>
      null;

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;
}

class _TestImageProvider implements ImageProvider<_TestImageProvider> {
  final int width;
  final int height;
  final double scale = 1;

  _TestImageProvider({
    required this.width,
    required this.height,
  });

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    return ImageStream()
      ..setCompleter(
        OneFrameImageStreamCompleter(_loadImage()),
      );
  }

  Future<ImageInfo> _loadImage() async {
    return ImageInfo(
      scale: scale,
      image: _TestImage(width, height),
    );
  }

  @override
  Future<_TestImageProvider> obtainKey(ImageConfiguration configuration) async {
    return this;
  }

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    _TestImageProvider key,
    ImageErrorListener handleError,
  ) {}

  @override
  ImageStream createStream(ImageConfiguration configuration) {
    throw UnimplementedError();
  }

  @override
  Future<bool> evict(
      {ImageCache? cache,
      ImageConfiguration configuration = ImageConfiguration.empty}) {
    throw UnimplementedError();
  }

  @override
  ImageStreamCompleter loadImage(
      _TestImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadImage());
  }

  @override
  // ignore: deprecated_member_use
  ImageStreamCompleter load(_TestImageProvider key, DecoderCallback decode) {
    throw UnimplementedError();
  }

  @override
  ImageStreamCompleter loadBuffer(
      // ignore: deprecated_member_use
      _TestImageProvider key, DecoderBufferCallback decode) {
    throw UnimplementedError();
  }

  @override
  Future<ImageCacheStatus?> obtainCacheStatus(
      {required ImageConfiguration configuration,
      ImageErrorListener? handleError}) {
    throw UnimplementedError();
  }
}
