part of image_crop;

@immutable
class ImageOptions {
  const ImageOptions({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  @override
  int get hashCode => hashValues(width, height);

  @override
  bool operator ==(Object other) =>
      other is ImageOptions && other.width == width && other.height == height;

  @override
  String toString() => '$ImageOptions(width: $width, height: $height)';
}

class ImageCrop {
  static const _channel = MethodChannel('plugins.lykhonis.com/image_crop');

  static Future<bool> requestPermissions() => _channel
      .invokeMethod<bool>('requestPermissions')
      .then((result) => result == true);

  static Future<ImageOptions> getImageOptions({
    required File file,
  }) async {
    final result = await _channel
        .invokeMethod<Map<String, int>>('getImageOptions', {'path': file.path});

    return ImageOptions(
      width: result?['width'] ?? 0,
      height: result?['height'] ?? 0,
    );
  }

  static Future<File?> cropImage({
    required File file,
    required Rect area,
    double? scale,
  }) =>
      _channel.invokeMethod<String>('cropImage', {
        'path': file.path,
        'left': area.left,
        'top': area.top,
        'right': area.right,
        'bottom': area.bottom,
        'scale': scale ?? 1.0,
      }).then((result) => result == null ? null : File(result));

  static Future<File?> sampleImage({
    required File file,
    int? preferredSize,
    int? preferredWidth,
    int? preferredHeight,
  }) async {
    assert(
      preferredSize == null &&
          (preferredWidth == null || preferredHeight == null),
      'Preferred size or both width and height of a resampled image must be specified.',
    );

    final path = await _channel.invokeMethod<String>('sampleImage', {
      'path': file.path,
      'maximumWidth': preferredSize ?? preferredWidth,
      'maximumHeight': preferredSize ?? preferredHeight,
    });

    if (path == null) return null;

    return File(path);
  }
}
