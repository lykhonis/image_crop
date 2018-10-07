package com.lykhonis.imagecrop;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.Build;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.Manifest.permission.READ_EXTERNAL_STORAGE;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

public final class ImageCropPlugin implements MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {
    private static final int PERMISSION_REQUEST_CODE = 13094;

    private final Activity activity;
    private Result permissionRequestResult;
    private ExecutorService executor;

    private ImageCropPlugin(Activity activity) {
        this.activity = activity;
        this.executor = Executors.newCachedThreadPool();
    }

    public static void registerWith(Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.lykhonis.com/image_crop");
        ImageCropPlugin instance = new ImageCropPlugin(registrar.activity());
        channel.setMethodCallHandler(instance);
        registrar.addRequestPermissionsResultListener(instance);
    }

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
            int maximumSize = call.argument("maximumSize");
            sampleImage(path, maximumSize, result);
        } else if ("getImageOptions".equals(call.method)) {
            String path = call.argument("path");
            getImageOptions(path, result);
        } else if ("requestPermissions".equals(call.method)) {
            requestPermissions(result);
        } else {
            result.notImplemented();
        }
    }

    private void cropImage(final String path, final RectF area, final float scale, final Result result) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                File srcFile = new File(path);
                if (!srcFile.exists()) {
                    result.error("INVALID", "Image source cannot be opened", null);
                    return;
                }

                Bitmap srcBitmap = BitmapFactory.decodeFile(path, null);
                if (srcBitmap == null) {
                    result.error("INVALID", "Image source cannot be decoded", null);
                    return;
                }

                int width = (int) (srcBitmap.getWidth() * area.width() * scale);
                int height = (int) (srcBitmap.getHeight() * area.height() * scale);

                Bitmap dstBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(dstBitmap);

                Paint paint = new Paint();
                paint.setAntiAlias(true);
                paint.setFilterBitmap(true);
                paint.setDither(true);

                Rect srcRect = new Rect((int) (srcBitmap.getWidth() * area.left), (int) (srcBitmap.getHeight() * area.top),
                                        (int) (srcBitmap.getWidth() * area.right), (int) (srcBitmap.getHeight() * area.bottom));
                Rect dstRect = new Rect(0, 0, width, height);

                canvas.drawBitmap(srcBitmap, srcRect, dstRect, paint);

                try {
                    File dstFile = createTemporaryImageFile();
                    compressBitmap(dstBitmap, dstFile);
                    result.success(dstFile.getAbsolutePath());
                } catch (IOException e) {
                    result.error("INVALID", "Image could not be saved", e);
                } finally {
                    canvas.setBitmap(null);
                    dstBitmap.recycle();
                    srcBitmap.recycle();
                }
            }
        });
    }

    private void sampleImage(final String path, final int maximumSize, final Result result) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                File srcFile = new File(path);
                if (!srcFile.exists()) {
                    result.error("INVALID", "Image source cannot be opened", null);
                    return;
                }

                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;

                BitmapFactory.decodeFile(path, options);

                int inSampleSize = calculateInSampleSize(options, maximumSize);
                if (inSampleSize == 1) {
                    result.success(path);
                    return;
                }

                options.inSampleSize = inSampleSize;
                options.inJustDecodeBounds = false;

                Bitmap bitmap = BitmapFactory.decodeFile(path, options);
                if (bitmap == null) {
                    result.error("INVALID", "Image source cannot be decoded", null);
                    return;
                }

                try {
                    File dstFile = createTemporaryImageFile();
                    compressBitmap(bitmap, dstFile);
                    result.success(dstFile.getAbsolutePath());
                } catch (IOException e) {
                    result.error("INVALID", "Image could not be saved", e);
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

    private int calculateInSampleSize(BitmapFactory.Options options, int maximumSize) {
        int height = options.outHeight;
        int width = options.outWidth;
        int inSampleSize = 1;

        if (height > maximumSize || width > maximumSize) {
            int halfHeight = height / 2;
            int halfWidth = width / 2;

            while ((halfHeight / inSampleSize) >= maximumSize && (halfWidth / inSampleSize) >= maximumSize) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    private void getImageOptions(final String path, final Result result) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                File file = new File(path);
                if (!file.exists()) {
                    result.error("INVALID", "Image source cannot be opened", null);
                    return;
                }

                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeFile(path, options);

                Map<String, Object> properties = new HashMap<>();
                properties.put("width", options.outWidth);
                properties.put("height", options.outHeight);

                result.success(properties);
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
}
