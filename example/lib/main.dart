import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getTemporaryDirectory();
  runApp(MyApp('${dir.path}/crop-result.png'));
}

class MyApp extends StatelessWidget {
  final String destPath;

  const MyApp(this.destPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Center(child: _Screen(destPath)),
        ),
      ),
    );
  }
}

class _Screen extends StatefulWidget {
  final String destPath;

  const _Screen(this.destPath);

  @override
  State<StatefulWidget> createState() {
    return _ScreenState();
  }
}

class _ScreenState extends State<_Screen> {
  CropController? _ctrl;
  MemoryImage? _image;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
          onPressed: _pickImage,
          child: const Text('Pick image', style: TextStyle(fontSize: 24)),
        ),
      );
    }

    final image = _image;
    if (image != null) {
      const spacer = SizedBox(height: 10);
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 5),
            ),
            child: Image(image: image),
          ),
          spacer,
          ElevatedButton(
            onPressed: () {
              setState(() {
                _image = null;
              });
            },
            child: const Text('Crop again'),
          ),
          spacer,
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick image'),
          ),
        ],
      );
    }

    return ImageCropper(
      ctrl,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      final source = FileImage(File(pickedFile.path));
      _ctrl?.dispose();
      _ctrl = CropController(
        imageProvider: source,
        target: const TargetSize(160, 90),
        maximumScale: 4,
        onDone: _onDone,
        onError: _onError,
      );
    });
  }

  void _onDone(MemoryImage img) async {
    if (mounted) {
      setState(() {
        _image = img;
      });
    }
  }

  void _onError(ImageCropError e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Something went wrong:\n$e'),
      showCloseIcon: true,
      duration: const Duration(seconds: 5),
    ));
  }
}
