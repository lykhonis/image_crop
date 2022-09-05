part of image_crop;

class ImageOptions {
  final int width;
  final int height;

  ImageOptions({
    required this.width,
    required this.height,
  });

  @override
  int get hashCode => hashValues(width, height);

  @override
  bool operator ==(other) =>
      other is ImageOptions && other.width == width && other.height == height;

  @override
  String toString() => '$runtimeType(width: $width, height: $height)';


}

class ImageCrop {
  static const _channel =
      const MethodChannel('plugins.lykhonis.com/image_crop');

  static Future<bool> requestPermissions() => _channel
      .invokeMethod('requestPermissions')
      .then<bool>((result) => result);

  static Future<ImageOptions> getImageOptions({
    required File file,
  }) async {
    final result =
        await _channel.invokeMethod('getImageOptions', {'path': file.path});
    
    debugPrint("\t width: " + result['width'].toString());
    debugPrint("\t height: " + result['height'].toString());
    return ImageOptions(
      width: result['width'],
      height: result['height'],
    );
  }

  static Future<File> cropImage({
    required File file,
    required Rect area,
    double? scale,
  }) =>
      _channel.invokeMethod('cropImage', {
        'path': file.path,
        'left': area.left,
        'top': area.top,
        'right': area.right,
        'bottom': area.bottom,
        'scale': scale ?? 1.0,
      }).then<File>((result) => File(result));

  static Future<File> cropImageRestricted({
    required File file,
    required Rect area,
    bool exact = false,
    int? preferredWidth,
    int? preferredHeight
  }) =>
      _channel.invokeMethod('cropImage', {
        'path': file.path,
        'left': area.left,
        'top': area.top,
        'right': area.right,
        'bottom': area.bottom,
        'scale': 1.0,
      }).then<File>((result) => File(result)).then<File>((result) => sampleImageRestricted(file: result, exact: exact, preferredWidth: preferredWidth, preferredHeight: preferredHeight));

  static Future<File> sampleImage({
    required File file,
    int? preferredSize,
    int? preferredWidth,
    int? preferredHeight,
  }) async {
    assert(() {
      if (preferredSize == null &&
          (preferredWidth == null || preferredHeight == null)) {
        throw ArgumentError(
            'Preferred size or both width and height of a resampled image must be specified.');
      }
      return true;
    }());

    final String path = await _channel.invokeMethod('sampleImage', {
      'path': file.path,
      'maximumWidth': preferredSize ?? preferredWidth,
      'maximumHeight': preferredSize ?? preferredHeight,
    });

    return File(path);
  }
  static Future<File> sampleImageRestricted({
    required File file,
    bool exact=false,
    int? preferredSize,
    int? preferredWidth,
    int? preferredHeight,
  }) async {
    assert(() {
      if (preferredSize == null &&
          (preferredWidth == null || preferredHeight == null)) {
        throw ArgumentError(
            'Preferred size or both width and height of a resampled image must be specified.');
      }
      return true;
    }());
    if(exact){
      final String path = await _channel.invokeMethod('sampleImageRestricted', {
        'path': file.path,
        'maximumWidth': preferredSize ?? preferredWidth,
        'maximumHeight': preferredSize ?? preferredHeight,
      });
      return File(path);
    }else{
      final String path = await _channel.invokeMethod('sampleImage', {
        'path': file.path,
        'maximumWidth': preferredSize ?? preferredWidth,
        'maximumHeight': preferredSize ?? preferredHeight,
      });
      return File(path);
    }


  }
}

