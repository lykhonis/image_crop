import 'package:flutter_test/flutter_test.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_crop/image_crop_platform_interface.dart';
import 'package:image_crop/image_crop_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImageCropPlatform
    with MockPlatformInterfaceMixin
    implements ImageCropPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ImageCropPlatform initialPlatform = ImageCropPlatform.instance;

  test('$MethodChannelImageCrop is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImageCrop>());
  });

  test('getPlatformVersion', () async {
    ImageCrop imageCropPlugin = ImageCrop();
    MockImageCropPlatform fakePlatform = MockImageCropPlatform();
    ImageCropPlatform.instance = fakePlatform;

    expect(await imageCropPlugin.getPlatformVersion(), '42');
  });
}
