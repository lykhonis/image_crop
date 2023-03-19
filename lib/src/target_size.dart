import 'dart:math';
import 'dart:ui';

class TargetSize {
  final int width;
  final int height;

  const TargetSize(this.width, this.height)
      : assert(width > 0, 'Width should be greater than 0'),
        assert(height > 0, 'Height should be greater than 0');

  const TargetSize.square(int size) : this(size, size);

  double get aspectRatio => width / height;

  /// Create a new Rect centered in [container] and with the maximum size to be
  /// fully contained in it
  Rect containedIn(Rect container) {
    assert(container.width >= 0,
        'Container width should be greater or equal to 0');
    assert(container.height >= 0,
        'Container height should be greater or equal to 0');

    final ratio = min(container.width / width, container.height / height);

    return Rect.fromCenter(
      center: container.center,
      width: width * ratio,
      height: height * ratio,
    );
  }

  /// Create a new Rect centered in [container] while completely covering it
  Rect cover(Rect container) {
    assert(container.width >= 0,
        'Container width should be greater or equal to 0');
    assert(container.height >= 0,
        'Container height should be greater or equal to 0');

    final ratio = max(container.width / width, container.height / height);

    return Rect.fromCenter(
      center: container.center,
      width: width * ratio,
      height: height * ratio,
    );
  }

  double scaleFactor(Rect view) {
    assert(
      view.size.aspectRatio.toStringAsFixed(2) ==
          (width / height).toStringAsFixed(2),
      'View must have the same aspect ratio as this TargetSize',
    );
    return view.width / width;
  }
}
