## 0.4.1

Community Contributions. Thank you!

* Dart 2.17 #89 (#91)
* Fixed a few typos (#87)
* Resolve #40 (#81)

## 0.4.0

* adds null safety

## 0.3.4

* fixes several issues related to scaling and multi-touch support

## 0.3.3

* migrate to the new Android APIs based on FlutterPlugin

## 0.3.2

* Fixes #33. Image rotation bug after cropping on iOS
* Flutter upgrade v1.13.5

## 0.3.1

* Fixes #19. Painting of the image is independent of top/left handles
* Visual correction of a grid. It was tilted by 1 point

## 0.3.0

* Android gradle upgrade to 3.4.1. Gradle 5.1.1
* Flutter upgrade 1.6.6
* Android target SDK 28

## 0.2.1

* Read exif information to provide proper width/height according to the orientation
* Rotate image prior cropping as needed per exif information

## 0.2.0

* Fit sampled images to specified maximum width/height on both iOS and Android
* Preserve exif information on Android when crop/sample image
* Updated example to illustrate higher quality cropped image production

## 0.1.3

* New widget options: Maximum scale, always show grid
* Adjusted scale to reflect original image size. If image scaled and fits in cropped area, scale is 1x
* Calculate sample size against large side of image to match smaller to preferred width/height
* Bug: ensure to display image on first frame
* Optimization: do not resample if image is smaller than preferred width/height

## 0.1.2

* Limit image to a crop area instead of view boundaries
* Don't adjust a size during scale to avoid misalignment
* After editing snap image back to a crop area. Auto scale if needed

## 0.1.1

* Fixed an exception when aspect ratio is not supplied
* Updated README with more information and screenshots

## 0.1.0

* Tools to resample by a factor, crop, and get options of images
* Display image provider
* Scale and crop image via widget
* Optional aspect ratio of crop area
