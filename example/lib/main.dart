import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_crop/image_crop.dart';

import 'plain_crop_painter.dart';

// Hidden import to let `flutter packages pub publish --dry-run` complete without errors
// FIXME: uncomment to try out example code
// import 'package:image_picker/image_picker.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final cropKey = GlobalKey<CropState>();
  File _file;
  File _sample;
  File _lastCropped;
  bool _fixedCrop = false;
  bool _plainCrop = false;

  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: _sample == null ? _buildOpeningImage() : _buildCroppingImage(),
        ),
      ),
    );
  }

  Widget _buildOpeningImage() {
    return Center(child: _buildOpenImage());
  }

  Widget _buildCroppingImage() {
    CropPainterBuilder cropPainterBuilder;

    if (_plainCrop) {
      cropPainterBuilder = (state) {
        return PlainCropPainter(state: state);
      };
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 140,
              child: FlatButton(
                child: Text(
                  _fixedCrop ? 'try adjustable' : 'try fixed',
                  style: Theme
                      .of(context)
                      .textTheme
                      .button
                      .copyWith(color: _plainCrop ? Colors.grey : Colors.white),
                ),
                onPressed: () {
                  if(_plainCrop) return;
                  setState(() {
                    _fixedCrop = !_fixedCrop;
                    cropKey.currentState.adjustable = !_fixedCrop;
                  });
                },
              ),
            ),
            Container(
              width: 140,
              child: FlatButton(
                child: Text(
                  _plainCrop ? 'try default crop' : 'try plain crop',
                  style: Theme
                      .of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () {
                  setState(() {
                    _plainCrop = !_plainCrop;
                    if(_plainCrop){
                      cropKey.currentState.adjustable = false;
                    }else{
                      cropKey.currentState.adjustable = !_fixedCrop;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: Crop.file(
            _sample,
            key: cropKey,
            aspectRatio: 1.0 / 1.0,
            cropPainterBuilder: cropPainterBuilder,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                child: Text(
                  'Crop Image',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () => _cropImage(),
              ),
              _buildOpenImage(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOpenImage() {
    return FlatButton(
      child: Text(
        'Open Image',
        style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
      ),
      onPressed: () => _openImage(),
    );
  }

  Future<void> _openImage() async {
    final file = await ImagePicker.pickImage(source: ImageSource.gallery);
    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size.longestSide.ceil(),
    );

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
    });
  }

  Future<void> _cropImage() async {
    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.sampleImage(
      file: _file,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    _lastCropped?.delete();
    _lastCropped = file;

    debugPrint('$file');
  }
}
