import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_crop_method_channel.dart';

abstract class ImageCropPlatform extends PlatformInterface {
  /// Constructs a ImageCropPlatform.
  ImageCropPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageCropPlatform _instance = MethodChannelImageCrop();

  /// The default instance of [ImageCropPlatform] to use.
  ///
  /// Defaults to [MethodChannelImageCrop].
  static ImageCropPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImageCropPlatform] when
  /// they register themselves.
  static set instance(ImageCropPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
