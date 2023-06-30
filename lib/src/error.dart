enum ImageCropErrorType {
  resize,
  load,
  noData,
  imageDecode,
  pictureToImage,
}

class ImageCropError {
  final ImageCropErrorType type;

  ImageCropError(this.type);

  ImageCropError.noData() : this(ImageCropErrorType.noData);

  factory ImageCropError.resize(Object error, StackTrace stackTrace) =>
      ImageCropErrorCauseTrace(ImageCropErrorType.resize, error, stackTrace);

  factory ImageCropError.load(Object error, StackTrace? stackTrace) =>
      ImageCropErrorOptTrace(ImageCropErrorType.load, error, stackTrace);

  factory ImageCropError.pictureToImage(Object error, StackTrace stackTrace) =>
      ImageCropErrorCauseTrace(
          ImageCropErrorType.pictureToImage, error, stackTrace);

  factory ImageCropError.imageDecode(Object error, StackTrace stackTrace) =>
      ImageCropErrorCauseTrace(
          ImageCropErrorType.imageDecode, error, stackTrace);

  StackTrace? get causeTrace => null;

  @override
  String toString() {
    return '$runtimeType.${type.name}';
  }
}

class ImageCropErrorOptTrace extends ImageCropError {
  final Object cause;
  @override
  final StackTrace? causeTrace;

  ImageCropErrorOptTrace(ImageCropErrorType type, this.cause, this.causeTrace)
      : super(type);

  @override
  String toString() {
    final trace = causeTrace == null ? '' : '\n\n$causeTrace';
    return '$runtimeType.${type.name}: $cause$trace';
  }
}

class ImageCropErrorCauseTrace extends ImageCropError {
  final Object cause;
  @override
  final StackTrace causeTrace;

  ImageCropErrorCauseTrace(ImageCropErrorType type, this.cause, this.causeTrace)
      : super(type);

  @override
  String toString() {
    return '$runtimeType.${type.name}: $cause\n\n$causeTrace';
  }
}