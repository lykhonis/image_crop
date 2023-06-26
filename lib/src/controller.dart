import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'const.dart';
import 'error.dart';
import 'target_size.dart';

void emptyFn() {}

enum _CropAction { move, resizeCropArea, scale }

enum CropHandle { topLeft, bottomRight }

typedef OnCropError = void Function(ImageCropError);
typedef OnCropDone = FutureOr<void> Function(MemoryImage);

class CropController extends ChangeNotifier {
  final ImageProvider imageProvider;
  final TargetSize target;
  double _maximumScale;

  final OnCropDone onDone;
  final OnCropError onError;

  ButtonStateNotifier? _submitBtnState;

  AnimationController? _activeAnimation;

  final bool alwaysShowGrid;

  AnimationController? get activeAnimation => _activeAnimation;

  set activeAnimation(AnimationController? value) {
    _activeAnimation = value;
    if (alwaysShowGrid) {
      _activeAnimation?.value = 1.0;
    }
  }

  ButtonStateNotifier get submitBtnState =>
      _submitBtnState ??= ButtonStateNotifier();

  Rect? _viewport;
  Rect _cropArea = Rect.zero;
  Rect _imageView = Rect.zero;
  double _scale = 1;
  _CropAction? _action;
  CropHandle? _handle;

  double _startScale = 1;

  late ImageStream _imageStream;

  ui.Image? _image;

  ui.Image? get image => _image;

  Rect get imageView => _imageView;

  Rect get cropArea => _cropArea;

  double get scale => _scale;

  CropController({
    required this.imageProvider,
    required this.onDone,
    required this.onError,
    required this.target,
    double maximumScale = 2.0,
    this.alwaysShowGrid = false,
  })  : assert(maximumScale > 0.0, 'maximumScale should be greater than 0.0'),
        _maximumScale = maximumScale;

  double get active => _activeAnimation?.value ?? 0.0;

  double _minimumScale(ui.Image image) {
    return max(_cropArea.width / image.width, _cropArea.height / image.height);
  }

  @override
  void dispose() {
    _activeAnimation?.dispose();
    _submitBtnState?.dispose();
    _submitBtnState = null;
    super.dispose();
  }

  Future<void> crop(double pixelRatio) async {
    final vp = _viewport;
    final image = _image;
    if (image == null || vp == null) {
      return;
    }

    submitBtnState.process();
    try {
      final recorder = ui.PictureRecorder();

      final src = Rect.fromLTWH(
        0.0,
        0.0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final offset = Offset.zero - _cropArea.topLeft;
      Canvas(recorder, vp)
        ..scale(pixelRatio / target.scaleFactor(_cropArea))
        ..translate(offset.dx, offset.dy)
        ..drawImageRect(
          image,
          src,
          _imageView,
          ui.Paint()..isAntiAlias = false,
        );

      final picture = recorder.endRecording();
      try {
        final image = await picture.toImage(
          (target.width * pixelRatio).toInt(),
          (target.height * pixelRatio).toInt(),
        );
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) {
            onError(ImageCropError.noData());
            return;
          }
          await onDone(
            MemoryImage(data.buffer.asUint8List(), scale: pixelRatio),
          );
        } catch (e, st) {
          onError(ImageCropError.imageDecode(e, st));
        } finally {
          image.dispose();
        }
      } catch (e, st) {
        onError(ImageCropError.pictureToImage(e, st));
      } finally {
        picture.dispose();
      }
    } catch (e, st) {
      onError(ImageCropError.resize(e, st));
    } finally {
      submitBtnState.ready();
    }
  }

  void resolveImage(ImageConfiguration config) {
    _imageStream = imageProvider.resolve(config);
    _imageStream
        .addListener(ImageStreamListener(_updateImage, onError: _onImageError));
  }

  void handleScaleStart(ScaleStartDetails details) {
    _activate();
    _action = null;
    _handle = _hitCropHandle(details.localFocalPoint);
    _startScale = _scale;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    final vp = _viewport;
    if (vp == null) {
      return;
    }
    switch (_getAction(details)) {
      case _CropAction.move:
        _moveImage(vp, details);
        break;
      case _CropAction.resizeCropArea:
        _resizeCropArea(vp, details);
        break;
      case _CropAction.scale:
        _scaleImage(vp, details);
        break;
    }
  }

  void _moveImage(Rect vp, ScaleUpdateDetails details) {
    final image = _image;
    if (image == null) {
      return;
    }

    final delta = details.focalPointDelta;
    final newView = _clampImageWithinCropArea(_imageView.shift(delta));
    if (newView != _imageView) {
      _imageView = newView;
      notifyListeners();
    }
  }

  void _scaleImage(Rect vp, ScaleUpdateDetails details) {
    final image = _image;
    if (image == null) {
      return;
    }

    _scale = _startScale * details.scale;
    if (_scale > _maximumScale) {
      _scale = _maximumScale;
    }

    final view = _clampImageWithinCropArea(
      Rect.fromCenter(
        center: _imageView.center,
        width: image.width * _scale,
        height: image.height * _scale,
      ),
    );
    if (view != _imageView) {
      _imageView = view;
      notifyListeners();
    }
  }

  void _resizeCropArea(Rect vp, ScaleUpdateDetails details) {
    final double delta;
    switch (_handle) {
      case null:
        return;
      case CropHandle.topLeft:
        delta = -details.focalPointDelta.dy;
        break;
      case CropHandle.bottomRight:
        delta = details.focalPointDelta.dy;
        break;
    }

    final height = _cropArea.height + delta * 2;
    final width = (height / _cropArea.height) * _cropArea.width;
    var area = _clampCropAreaWithinViewport(
      vp.deflate(kCropAreaPadding),
      Rect.fromCenter(
        center: _cropArea.center,
        width: width,
        height: height,
      ),
    );
    final smaller = min(area.width, area.height);
    if (smaller < kMinCropArea) {
      area = target.cover(Rect.fromCenter(
        center: _cropArea.center,
        width: kMinCropArea,
        height: kMinCropArea,
      ));
    }
    if (area != _cropArea) {
      _cropArea = area;
      _imageView = _clampImageWithinCropArea(_imageView);
      notifyListeners();
    }
  }

  _CropAction _getAction(ScaleUpdateDetails details) {
    if (_action != null) {
      return _action!;
    }
    if (_handle == null) {
      return _action =
          details.pointerCount == 2 ? _CropAction.scale : _CropAction.move;
    } else {
      return _action = _CropAction.resizeCropArea;
    }
  }

  void handleScaleEnd(ScaleEndDetails details) {
    if (alwaysShowGrid == false) {
      _activeAnimation?.animateTo(
        0.0,
        curve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  void _activate() {
    _activeAnimation?.animateTo(
      1.0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  CropHandle? _hitCropHandle(Offset hitPoint) {
    final topHitBox = Rect.fromCenter(
      center: _cropArea.topLeft,
      width: kCropHandleHitSize,
      height: kCropHandleHitSize,
    );
    if (topHitBox.contains(hitPoint)) {
      return CropHandle.topLeft;
    }

    final bottomHitBox = Rect.fromCenter(
      center: _cropArea.bottomRight,
      width: kCropHandleHitSize,
      height: kCropHandleHitSize,
    );
    if (bottomHitBox.contains(hitPoint)) {
      return CropHandle.bottomRight;
    }

    return null;
  }

  Rect _clampImageWithinCropArea(Rect view) {
    final image = _image;
    if (image == null) {
      return view;
    }

    final minScale = _minimumScale(image);
    if (_scale < minScale) {
      _scale = minScale;
      view = Rect.fromCenter(
        center: view.center,
        width: image.width * _scale,
        height: image.height * _scale,
      );
    }

    final boundaries = _cropArea;
    var dx = 0.0;
    var dy = 0.0;

    if (boundaries.left < view.left) {
      dx = boundaries.left - view.left;
    } else if (boundaries.right > view.right) {
      dx = boundaries.right - view.right;
    }
    if (boundaries.top < view.top) {
      dy = boundaries.top - view.top;
    } else if (boundaries.bottom > view.bottom) {
      dy = boundaries.bottom - view.bottom;
    }

    return (dx == 0.0 && dy == 0.0) ? view : view.translate(dx, dy);
  }

  Rect _clampCropAreaWithinViewport(Rect vp, Rect area) {
    return vp.width < area.width || vp.height < area.height
        ? target.containedIn(vp)
        : area;
  }

  Rect setViewport(Size size) {
    if (_viewport?.size == size) {
      return _viewport!;
    }
    final vp = _viewport = Offset.zero & size;
    _cropArea = target.containedIn(vp.deflate(kCropAreaPadding));
    _centerImageView();
    return vp;
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    final image = imageInfo.image;
    _image = image;
    _scale = imageInfo.scale;

    _centerImageView();
    notifyListeners();
  }

  void _centerImageView() {
    final image = _image;
    final vp = _viewport;

    if (image != null && vp != null) {
      final target = TargetSize(image.width, image.height);
      _imageView = target.cover(vp);
      _scale = target.scaleFactor(_imageView);
      if (_scale > _maximumScale) {
        _maximumScale = _scale;
      }
    }
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    onError(ImageCropError.load(error, stackTrace));
  }
}
