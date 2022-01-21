# Image Cropping plugin for Flutter

A flutter plugin to crop image on iOS and Android.

![Image Cropping Preview](assets/image_cropping_preview.gif)

The plugin comes with a `Crop` widget. The widget renders only image, overlay, and handles to crop an image. Thus it can be composed with other widgets to build custom image cropping experience. 

The plugin is working with files to avoid passing large amount of data through method channels. Files are stored in cache folders of iOS and Android. Thus if there is a need to save actual cropped image, ensure to copy the file to other location.

All of the computation intensive work is done off a main thread via dispatch queues on iOS and cache thread pool on Android.

*Note*: This plugin is still under development, some features are not available yet and testing has been limited.

## Installation
Add `image_crop` [![image_crop](https://img.shields.io/pub/v/image_crop.svg)](https://pub.dartlang.org/packages/image_crop) as [a dependency in `pubspec.yaml`](https://flutter.io/using-packages/#managing-package-dependencies--versions).

## Using
Create a widget to load and edit an image:
```dart
final cropKey = GlobalKey<CropState>();

Widget _buildCropImage() {
  return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20.0),
      child: Crop(
        key: cropKey,
        image: Image.file(imageFile),
        aspectRatio: 4.0 / 3.0,
      ),
  );
}
```
Access cropping values:
- scale is a factor to proportionally scale image's width and height when cropped. `1.0` is no scale needed.
- area is a rectangle indicating fractional positions on the image to crop from.
```dart
final crop = cropKey.currentState;
// or
// final crop = Crop.of(context);
final scale = crop.scale;
final area = crop.area;

if (area == null) {
    // cannot crop, widget is not setup
    // ...
}
```
Accessing and working with images. As a convenience function to request permissions to access photos.
```dart
final permissionsGranted = await ImageCrop.requestPermissions();
``` 
Read image options, such as: width and height. This is efficient implementation that does not decode nor load actual image into a memory.
```dart
final options = await getImageOptions(file: file);
debugPrint('image width: ${options.width}, height: ${options.height}');
```
If a large image is to be loaded into the memory, there is a sampling function that relies on a native platform to proportionally scale down the image before loading it to the memory. e.g. resample image to get down to `1024x4096` dimension as close as possible. If it is a square `preferredSize` can be used to specify both width and height. Prefer to leverage this functionality when displaying images in UI.
```dart
final sampleFile = await ImageCrop.sampleImage(
    file: originalFile,
    preferredWidth: 1024,
    preferredHeight: 4096,
);
```
Once `Crop` widget is ready, there is a native support of cropping and scaling an image. In order to produce higher quality cropped image, rely on sampling image with preferred maximum width and height. Scale up a resolution of the sampled image. When cropped, the image is in higher resolution. Example is illustrated below:
```dart
final sampledFile = await ImageCrop.sampleImage(
    file: originalFile,
    preferredWidth: (1024 / crop.scale).round(),
    preferredHeight: (4096 / crop.scale).round(),
);

final croppedFile = await ImageCrop.cropImage(
    file: sampledFile,
    area: crop.area,
);
```
