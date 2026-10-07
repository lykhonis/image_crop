import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_crop_platform_interface.dart';

/// An implementation of [ImageCropPlatform] that uses method channels.
class MethodChannelImageCrop extends ImageCropPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_crop');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
