enum ImageCropErrorType {
  resize,
  load;
}

class ImageCropError {
  final ImageCropErrorType type;
  final Object cause;
  final StackTrace? causeTrace;

  ImageCropError(this.type, this.cause, this.causeTrace);

  ImageCropError.resize(Object error, StackTrace stackTrace)
      : this(ImageCropErrorType.resize, error, stackTrace);

  ImageCropError.load(Object error, StackTrace? stackTrace)
      : this(ImageCropErrorType.load, error, stackTrace);

  @override
  String toString() {
    return '$runtimeType: ${type.name}\nCause: $cause\n\n$causeTrace';
  }
}
