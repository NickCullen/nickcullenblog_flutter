import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(App());
}

class App extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraApp(),
    );
  }
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  String _barcodeRead = "";
  Timer _timer;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      _startTimer();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        AspectRatio(
          aspectRatio:
          controller.value.aspectRatio,
          child: CameraPreview(controller)
        ),
        
        Container(
          alignment: Alignment.bottomCenter,
          child: Text(
            _barcodeRead.length > 0 ? _barcodeRead : "No Barcode",
            textAlign: TextAlign.center
          ),
        )
      ],       
    );
  }

  void _startTimer() {
    _timer = new Timer(Duration(seconds: 3), _timerElapsed);
  }

  void _stopTimer() {
    if(_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  Future<void> _timerElapsed() async{
    _stopTimer();

    File file = await _takePicture();

    await _readBarcode(file);

    _startTimer();
  }

  Future<File> _takePicture() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/barcode';
    await Directory(dirPath).create(recursive: true);
    final File file = new File('$dirPath/barcode.jpg');
    
    if(await file.exists())
      await file.delete();
    
    await controller.takePicture(file.path);
    return file;
  }

  Future _readBarcode(File file) async {
    FirebaseVisionImage firebaseImage = FirebaseVisionImage.fromFile(file);
    final BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    
    final List<Barcode> barcodes = await barcodeDetector.detectInImage(firebaseImage);
    
    _barcodeRead = "";
    for(Barcode barcode in barcodes) {
      _barcodeRead += barcode.rawValue + ", ";
    }
    
    setState(() {});
  }
}