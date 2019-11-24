#import "ImageCropPlugin.h"

#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ImageCropPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"plugins.lykhonis.com/image_crop"
                                   binaryMessenger:[registrar messenger]];
  ImageCropPlugin* instance = [ImageCropPlugin new];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"cropImage" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* left = (NSNumber*)call.arguments[@"left"];
        NSNumber* top = (NSNumber*)call.arguments[@"top"];
        NSNumber* right = (NSNumber*)call.arguments[@"right"];
        NSNumber* bottom = (NSNumber*)call.arguments[@"bottom"];
        NSNumber* scale = (NSNumber*)call.arguments[@"scale"];
        CGRect area = CGRectMake(left.floatValue, top.floatValue,
                                 right.floatValue - left.floatValue,
                                 bottom.floatValue - top.floatValue);
        [self cropImage:path area:area scale:scale result:result];
    } else if ([@"sampleImage" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* maximumWidth = (NSNumber*)call.arguments[@"maximumWidth"];
        NSNumber* maximumHeight = (NSNumber*)call.arguments[@"maximumHeight"];
        [self sampleImage:path
             maximumWidth:maximumWidth
            maximumHeight:maximumHeight
                   result:result];
    } else if ([@"getImageOptions" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        [self getImageOptions:path result:result];
    } else if ([@"requestPermissions" isEqualToString:call.method]){
        [self requestPermissionsWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)cropImage:(NSString*)path
             area:(CGRect)area
            scale:(NSNumber*)scale
           result:(FlutterResult)result {
    [self execute:^{
        NSURL* url = [NSURL fileURLWithPath:path];
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
        if (imageSource == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source cannot be opened"
                                       details:nil]);
            return;
        }

        CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                               (id) kCGImageSourceCreateThumbnailWithTransform: @YES,
                                                               (id) kCGImageSourceCreateThumbnailFromImageAlways: @YES
                                                               };

        CGImageRef image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
        

        if (image == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image cannot be opened"
                                       details:nil]);
            CFRelease(imageSource);
            return;
        }
        
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t scaledWidth = (size_t) (width * area.size.width * scale.floatValue);
        size_t scaledHeight = (size_t) (height * area.size.height * scale.floatValue);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
        size_t bytesPerRow = CGImageGetBytesPerRow(image) / width * scaledWidth;
        CGImageAlphaInfo bitmapInfo = CGImageGetAlphaInfo(image);
        CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
        
        CGImageRef croppedImage = CGImageCreateWithImageInRect(image,
                                                               CGRectMake(width * area.origin.x,
                                                                          height * area.origin.y,
                                                                          width * area.size.width,
                                                                          height * area.size.height));
        
        CFRelease(image);
        CFRelease(imageSource);
        
        if (scale.floatValue != 1.0) {
            CGContextRef context = CGBitmapContextCreate(NULL,
                                                         scaledWidth,
                                                         scaledHeight,
                                                         bitsPerComponent,
                                                         bytesPerRow,
                                                         colorspace,
                                                         bitmapInfo);
            
            if (context == NULL) {
                result([FlutterError errorWithCode:@"INVALID"
                                           message:@"Image cannot be scaled"
                                           details:nil]);
                CFRelease(croppedImage);
                return;
            }
            
            CGRect rect = CGContextGetClipBoundingBox(context);
            CGContextDrawImage(context, rect, croppedImage);
            
            CGImageRef scaledImage = CGBitmapContextCreateImage(context);
            
            CGContextRelease(context);
            CFRelease(croppedImage);
            
            croppedImage = scaledImage;
        }
        
        NSURL* croppedUrl = [self createTemporaryImageUrl];
        bool saved = [self saveImage:croppedImage url:croppedUrl];
        CFRelease(croppedImage);
        
        if (saved) {
            result(croppedUrl.path);
        } else {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Cropped image cannot be saved"
                                       details:nil]);
        }
    }];
}

- (void)sampleImage:(NSString*)path
       maximumWidth:(NSNumber*)maximumWidth
      maximumHeight:(NSNumber*)maximumHeight
             result:(FlutterResult)result {
    [self execute:^{
        NSURL* url = [NSURL fileURLWithPath:path];
        CGImageSourceRef image = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
        if (image == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source cannot be opened"
                                       details:nil]);
            return;
        }

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil);

        if (properties == NULL) {
            CFRelease(image);
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source properties cannot be copied"
                                       details:nil]);
            return;
        }

        NSNumber* width = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
        NSNumber* height = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
        CFRelease(properties);

        double widthRatio = MIN(1.0, maximumWidth.doubleValue / width.doubleValue);
        double heightRatio = MIN(1.0, maximumHeight.doubleValue / height.doubleValue);
        double ratio = MAX(widthRatio, heightRatio);
        NSNumber* maximumSize = @(MAX(width.doubleValue * ratio, height.doubleValue * ratio));

        CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                               (id) kCGImageSourceCreateThumbnailWithTransform: @YES,
                                                               (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                               (id) kCGImageSourceThumbnailMaxPixelSize : maximumSize
                                                               };
        CGImageRef sampleImage = CGImageSourceCreateThumbnailAtIndex(image, 0, options);
        CFRelease(image);

        if (sampleImage == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image sample cannot be created"
                                       details:nil]);
            return;
        }

        NSURL* sampleUrl = [self createTemporaryImageUrl];
        bool saved = [self saveImage:sampleImage url:sampleUrl];
        CFRelease(sampleImage);
        
        if (saved) {
            result(sampleUrl.path);
        } else {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image sample cannot be saved"
                                       details:nil]);
        }
    }];
}

- (void)getImageOptions:(NSString*)path result:(FlutterResult)result {
    [self execute:^{
        NSURL* url = [NSURL fileURLWithPath:path];
        CGImageSourceRef image = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
        if (image == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source cannot be opened"
                                       details:nil]);
            return;
        }

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil);
        CFRelease(image);
        
        if (properties == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source properties cannot be copied"
                                       details:nil]);
            return;
        }

        NSNumber* width = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
        NSNumber* height = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
        CFRelease(properties);

        result(@{ @"width": width,  @"height": height });
    }];
}

- (void)requestPermissionsWithResult:(FlutterResult)result {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            result(@YES);
        } else {
            result(@NO);
        }
    }];
}

- (bool)saveImage:(CGImageRef)image url:(NSURL*)url {
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef) url, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(destination, image, NULL);
    
    bool finilized = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    return finilized;
}

- (NSURL*)createTemporaryImageUrl {
    NSString* temproraryDirectory = NSTemporaryDirectory();
    NSString* guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString* sampleName = [[@"image_crop_" stringByAppendingString:guid] stringByAppendingString:@".jpg"];
    NSString* samplePath = [temproraryDirectory stringByAppendingPathComponent:sampleName];
    return [NSURL fileURLWithPath:samplePath];
}

- (void)execute:(void (^)(void))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
