import 'dart:ui';

const kCropGridColumnCount = 3;
const kCropGridRowCount = 3;
const kCropGridColor = Color.fromRGBO(0xd0, 0xd0, 0xd0, 0.9);
const kCropOverlayActiveOpacity = 0.3;
const kCropOverlayInactiveOpacity = 0.7;
const kCropHandleColor = Color.fromRGBO(0xd0, 0xd0, 0xd0, 1.0);
const kCropHandleSize = 10.0;
const kCropHandleHitSize = 48.0;
const kCropAreaPadding = kCropHandleSize * 2;
const kMinCropArea = 32.0;
