import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutml/face_decorator.dart';
import 'package:flutml/face_detector_util.dart';
import 'package:flutml/image_util.dart';
import 'package:flutml/main.dart';
import 'package:flutter/material.dart';
import 'package:rect_getter/rect_getter.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Face> faces;
  ui.Image overlayImage;
  Size imageSize;

  final ImageUtil imageUtil = ImageUtil();
  final faceDetector = FaceDetectorUtil();
  RectGetter rectGetter;

  _MyHomePageState({this.faces});

  CameraController controller;

  @override
  void initState() {
    super.initState();
    _loadImage();
    final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    controller = CameraController(camera, ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
      controller.startImageStream((imageData) {
        faceDetector.getSample(imageData).then((faces) {
          if (faces != null) {
            setState(() {
              this.imageSize = faces.imageSize;
              this.faces = faces.faces;
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.value.isInitialized) {
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: _buildImage());
    } else {
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(child: CircularProgressIndicator()));
    }
  }

  Widget _buildImage() {
    return Center(
        child: Container(
            foregroundDecoration: FaceDecoration(
                imageSize, faces, overlayImage, controller.value.aspectRatio),
            child: _getAspectRationWidget()));
  }

  Widget _getAspectRationWidget() {
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }

  _loadImage() {
    ImageUtil()
        .getAssetImage("samples/mustashe.png", ImageConfiguration())
        .then((image) {
      overlayImage = image;
    });
  }
}
