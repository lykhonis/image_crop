import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
  }
  Future<String> getFilePath() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory(); // 1
    String appDocumentsPath = appDocumentsDirectory.path; // 2
    String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3

    return filePath;
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
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample, key: cropKey),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
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
    return TextButton(
      child: Text(
        'Open Image',
        style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
      ),
      onPressed: () => _openImage(),
    );
  }

  Future<void> _openImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    final file = File(pickedFile.path);
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


    final file = await ImageCrop.cropImageRestricted(
      file: sample,
      area: area,
      exact: true,
      preferredHeight: 800,
      preferredWidth: 600
    );

    //restricted crop height and width
    debugPrint("Restricted crop: ");
    debugPrint(ImageCrop.getImageOptions(file: file).toString());


    final file2 = await ImageCrop.cropImage(
        file: sample,
        area: area,
    );
    //unrestricted crop height and width
    debugPrint("Unrestricted crop: ");
    debugPrint(ImageCrop.getImageOptions(file: file2).toString());


    var rawCoords = cropKey.currentState.rawCropAreaCoords;
    if(rawCoords != null){
      debugPrint("crop area raw coordinates: \n" + "\t top left: " + rawCoords[0].toString()
          + "\n\t width: " + rawCoords[1].toString()
          + "\n\t height: " + rawCoords[2].toString());
    }else{
      debugPrint("no area specified");
    }

    var coords = cropKey.currentState.cropAreaCoords;
    if(coords != null) {
      debugPrint(
          "crop area relative coordinates: \n" + "\t top left: " + coords[0].toString()
              + "\n\t width: " + coords[1].toString()
              + "\n\t height: " + coords[2].toString());
    }else{
      debugPrint("no area specified");
    }

    sample.delete();

    _lastCropped?.delete();
    _lastCropped = file;

    debugPrint('$file');




  }
}

