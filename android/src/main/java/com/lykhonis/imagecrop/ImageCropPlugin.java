package com.lykhonis.imagecrop;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.Build;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import androidx.annotation.NonNull;
import androidx.exifinterface.media.ExifInterface;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import static android.Manifest.permission.READ_EXTERNAL_STORAGE;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

public final class ImageCropPlugin implements FlutterPlugin , ActivityAware, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {
    private static final int PERMISSION_REQUEST_CODE = 13094;

    private MethodChannel channel;

    private ActivityPluginBinding binding;
    private Activity activity;
    private Result permissionRequestResult;
    private ExecutorService executor;

    private ImageCropPlugin(Activity activity) {
        this.activity = activity;
    }

    public ImageCropPlugin(){ }

    /**
     * legacy APIs
     */
    public static void registerWith(Registrar registrar) {
        ImageCropPlugin instance = new ImageCropPlugin(registrar.activity());
        instance.setup(registrar.messenger());
        registrar.addRequestPermissionsResultListener(instance);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
      this.setup(binding.getBinaryMessenger());
    }
  
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        binding = activityPluginBinding;
        activity = activityPluginBinding.getActivity();
        activityPluginBinding.addRequestPermissionsResultListener(this);
    }
   
    @Override
    public void onDetachedFromActivity() {
        activity = null;
        if(binding != null){
            binding.removeRequestPermissionsResultListener(this);
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
        this.onAttachedToActivity(activityPluginBinding);
    }
  
    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.onDetachedFromActivity();
    }
  
    private void setup(BinaryMessenger messenger) {
        channel = new MethodChannel(messenger, "plugins.lykhonis.com/image_crop");
        channel.setMethodCallHandler(this);
    }


    @SuppressWarnings("ConstantConditions")
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if ("cropImage".equals(call.method)) {
            String path = call.argument("path");
            double scale = call.argument("scale");
            double left = call.argument("left");
            double top = call.argument("top");
            double right = call.argument("right");
            double bottom = call.argument("bottom");
            RectF area = new RectF((float) left, (float) top, (float) right, (float) bottom);
            cropImage(path, area, (float) scale, result);
        } else if ("sampleImage".equals(call.method)) {
            String path = call.argument("path");
            int maximumWidth = call.argument("maximumWidth");
            int maximumHeight = call.argument("maximumHeight");
            sampleImage(path, maximumWidth, maximumHeight, result);
        } else if ("getImageOptions".equals(call.method)) {
            String path = call.argument("path");
            getImageOptions(path, result);
        } else if ("requestPermissions".equals(call.method)) {
            requestPermissions(result);
        } else {
            result.notImplemented();
        }
    }

    private synchronized void io(@NonNull Runnable runnable) {
        if (executor == null) {
            executor = Executors.newCachedThreadPool();
        }
        executor.execute(runnable);
    }

    private void ui(@NonNull Runnable runnable) {
        activity.runOnUiThread(runnable);
    }

    private void cropImage(final String path, final RectF area, final float scale, final Result result) {
        io(new Runnable() {
            @Override
            public void run() {
                File srcFile = new File(path);
                if (!srcFile.exists()) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image source cannot be opened", null);
                        }
                    });
                    return;
                }

                Bitmap srcBitmap = BitmapFactory.decodeFile(path, null);
                if (srcBitmap == null) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image source cannot be decoded", null);
                        }
                    });
                    return;
                }

                ImageOptions options = decodeImageOptions(path);
                if (options.isFlippedDimensions()) {
                    Matrix transformations = new Matrix();
                    transformations.postRotate(options.getDegrees());
                    Bitmap oldBitmap = srcBitmap;
                    srcBitmap = Bitmap.createBitmap(oldBitmap,
                                                    0, 0,
                                                    oldBitmap.getWidth(), oldBitmap.getHeight(),
                                                    transformations, true);
                    oldBitmap.recycle();
                }

                int width = (int) (options.getWidth() * area.width() * scale);
                int height = (int) (options.getHeight() * area.height() * scale);

                Bitmap dstBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(dstBitmap);

                Paint paint = new Paint();
                paint.setAntiAlias(true);
                paint.setFilterBitmap(true);
                paint.setDither(true);

                Rect srcRect = new Rect((int) (srcBitmap.getWidth() * area.left),
                                        (int) (srcBitmap.getHeight() * area.top),
                                        (int) (srcBitmap.getWidth() * area.right),
                                        (int) (srcBitmap.getHeight() * area.bottom));
                Rect dstRect = new Rect(0, 0, width, height);
                canvas.drawBitmap(srcBitmap, srcRect, dstRect, paint);

                // TODO: Research a way to optimize rendering via matrix to reduce memory print.
//                Matrix transformations = new Matrix();
//                transformations.mapRect(new RectF(0, 0,
//                                                  options.getWidth(), options.getHeight()));
//                transformations.postTranslate(-options.getWidth() / 2f * area.left,
//                                              -options.getHeight() / 2f * area.top);
//                transformations.postRotate(options.getDegrees(),
//                                           options.getWidth() / 2f * area.width(),
//                                           options.getHeight() / 2f * area.height());
//                canvas.drawBitmap(srcBitmap, transformations, paint);

                try {
                    final File dstFile = createTemporaryImageFile();
                    compressBitmap(dstBitmap, dstFile);
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.success(dstFile.getAbsolutePath());
                        }
                    });
                } catch (final IOException e) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image could not be saved", e);
                        }
                    });
                } finally {
                    canvas.setBitmap(null);
                    dstBitmap.recycle();
                    srcBitmap.recycle();
                }
            }
        });
    }

    private void sampleImage(final String path, final int maximumWidth, final int maximumHeight, final Result result) {
        io(new Runnable() {
            @Override
            public void run() {
                File srcFile = new File(path);
                if (!srcFile.exists()) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image source cannot be opened", null);
                        }
                    });
                    return;
                }

                ImageOptions options = decodeImageOptions(path);
                BitmapFactory.Options bitmapOptions = new BitmapFactory.Options();
                bitmapOptions.inSampleSize = calculateInSampleSize(options.getWidth(), options.getHeight(),
                                                                   maximumWidth, maximumHeight);

                Bitmap bitmap = BitmapFactory.decodeFile(path, bitmapOptions);
                if (bitmap == null) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image source cannot be decoded", null);
                        }
                    });
                    return;
                }

                if (options.getWidth() > maximumWidth && options.getHeight() > maximumHeight) {
                    float ratio = Math.max(maximumWidth / (float) options.getWidth(), maximumHeight / (float) options.getHeight());
                    Bitmap sample = bitmap;
                    bitmap = Bitmap.createScaledBitmap(sample, Math.round(bitmap.getWidth() * ratio), Math.round(bitmap.getHeight() * ratio), true);
                    sample.recycle();
                }

                try {
                    final File dstFile = createTemporaryImageFile();
                    compressBitmap(bitmap, dstFile);
                    copyExif(srcFile, dstFile);
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.success(dstFile.getAbsolutePath());
                        }
                    });
                } catch (final IOException e) {
                    ui(new Runnable() {
                        @Override
                        public void run() {
                            result.error("INVALID", "Image could not be saved", e);
                        }
                    });
                } finally {
                    bitmap.recycle();
                }
            }
        });
    }

    @SuppressWarnings("TryFinallyCanBeTryWithResources")
    private void compressBitmap(Bitmap bitmap, File file) throws IOException {
        OutputStream outputStream = new FileOutputStream(file);
        try {
            boolean compressed = bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
            if (!compressed) {
                throw new IOException("Failed to compress bitmap into JPEG");
            }
        } finally {
            try {
                outputStream.close();
            } catch (IOException ignore) {
            }
        }
    }

    private int calculateInSampleSize(int width, int height, int maximumWidth, int maximumHeight) {
        int inSampleSize = 1;

        if (height > maximumHeight || width > maximumWidth) {
            int halfHeight = height / 2;
            int halfWidth = width / 2;

            while ((halfHeight / inSampleSize) >= maximumHeight && (halfWidth / inSampleSize) >= maximumWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    private void getImageOptions(final String path, final Result result) {
        io(new Runnable() {
            @Override
            public void run() {
                File file = new File(path);
                if (!file.exists()) {
                    result.error("INVALID", "Image source cannot be opened", null);
                    return;
                }

                ImageOptions options = decodeImageOptions(path);
                final Map<String, Object> properties = new HashMap<>();
                properties.put("width", options.getWidth());
                properties.put("height", options.getHeight());

                ui(new Runnable() {
                    @Override
                    public void run() {
                        result.success(properties);
                    }
                });
            }
        });
    }

    private void requestPermissions(Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (activity.checkSelfPermission(READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED &&
                    activity.checkSelfPermission(WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                result.success(true);
            } else {
                permissionRequestResult = result;
                activity.requestPermissions(new String[]{READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE}, PERMISSION_REQUEST_CODE);
            }
        } else {
            result.success(true);
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PERMISSION_REQUEST_CODE && permissionRequestResult != null) {
            int readExternalStorage = getPermissionGrantResult(READ_EXTERNAL_STORAGE, permissions, grantResults);
            int writeExternalStorage = getPermissionGrantResult(WRITE_EXTERNAL_STORAGE, permissions, grantResults);
            permissionRequestResult.success(readExternalStorage == PackageManager.PERMISSION_GRANTED &&
                                                    writeExternalStorage == PackageManager.PERMISSION_GRANTED);
            permissionRequestResult = null;
        }
        return false;
    }

    private int getPermissionGrantResult(String permission, String[] permissions, int[] grantResults) {
        for (int i = 0; i < permission.length(); i++) {
            if (permission.equals(permissions[i])) {
                return grantResults[i];
            }
        }
        return PackageManager.PERMISSION_DENIED;
    }

    private File createTemporaryImageFile() throws IOException {
        File directory = activity.getCacheDir();
        String name = "image_crop_" + UUID.randomUUID().toString();
        return File.createTempFile(name, ".jpg", directory);
    }

    private ImageOptions decodeImageOptions(String path) {
        int rotationDegrees = 0;
        try {
            ExifInterface exif = new ExifInterface(path);
            rotationDegrees = exif.getRotationDegrees();
        } catch (IOException e) {
            Log.e("ImageCrop", "Failed to read a file " + path, e);
        }
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, options);
        return new ImageOptions(options.outWidth, options.outHeight, rotationDegrees);
    }

    private void copyExif(File source, File destination) {
        try {
            ExifInterface sourceExif = new ExifInterface(source.getAbsolutePath());
            ExifInterface destinationExif = new ExifInterface(destination.getAbsolutePath());

            List<String> tags =
                    Arrays.asList(
                            ExifInterface.TAG_F_NUMBER,
                            ExifInterface.TAG_EXPOSURE_TIME,
                            ExifInterface.TAG_PHOTOGRAPHIC_SENSITIVITY,
                            ExifInterface.TAG_GPS_ALTITUDE,
                            ExifInterface.TAG_GPS_ALTITUDE_REF,
                            ExifInterface.TAG_FOCAL_LENGTH,
                            ExifInterface.TAG_GPS_DATESTAMP,
                            ExifInterface.TAG_WHITE_BALANCE,
                            ExifInterface.TAG_GPS_PROCESSING_METHOD,
                            ExifInterface.TAG_GPS_TIMESTAMP,
                            ExifInterface.TAG_DATETIME,
                            ExifInterface.TAG_FLASH,
                            ExifInterface.TAG_GPS_LATITUDE,
                            ExifInterface.TAG_GPS_LATITUDE_REF,
                            ExifInterface.TAG_GPS_LONGITUDE,
                            ExifInterface.TAG_GPS_LONGITUDE_REF,
                            ExifInterface.TAG_MAKE,
                            ExifInterface.TAG_MODEL,
                            ExifInterface.TAG_ORIENTATION);

            for (String tag : tags) {
                String attribute = sourceExif.getAttribute(tag);
                if (attribute != null) {
                    destinationExif.setAttribute(tag, attribute);
                }
            }

            destinationExif.saveAttributes();
        } catch (IOException e) {
            Log.e("ImageCrop", "Failed to preserve Exif information", e);
        }
    }

    private static final class ImageOptions {
        private final int width;
        private final int height;
        private final int degrees;

        ImageOptions(int width, int height, int degrees) {
            this.width = width;
            this.height = height;
            this.degrees = degrees;
        }

        int getHeight() {
            return (isFlippedDimensions() && degrees != 180) ? width : height;
        }

        int getWidth() {
            return (isFlippedDimensions() && degrees != 180)  ? height : width;
        }

        int getDegrees() {
            return degrees;
        }

        boolean isFlippedDimensions() {
            return degrees == 90 || degrees == 270 || degrees == 180;
        }

        public boolean isRotated() {
            return degrees != 0;
        }
    }
}
