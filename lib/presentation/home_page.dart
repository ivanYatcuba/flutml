import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutml/face_decorator.dart';
import 'package:flutml/face_detector_util.dart';
import 'package:flutml/image_util.dart';
import 'package:flutml/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  CameraController controller;

  final ImageUtil imageUtil = ImageUtil();
  final faceDetector = FaceDetectorUtil();

  var initialized = false;

  _MyHomePageState({this.faces});

  @override
  void initState() {
    super.initState();
    final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    controller = CameraController(camera, ResolutionPreset.low);
    _loadImage();
    initializeController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  var streamStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          if (value.isInitialized) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!streamStarted) {
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
                streamStarted = true;
              }
            });
            return getReadyForUseContent();
          } else {
            return Scaffold(
                appBar: AppBar(
                  title: Text(widget.title),
                ),
                body: Center(child: CircularProgressIndicator()));
          }
        },
      ),
    );
  }

  Widget getReadyForUseContent() {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Container(
              foregroundDecoration: FaceDecoration(
                  imageSize, faces, overlayImage, controller.value.aspectRatio),
              child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller))),
        ));
  }

  Future initializeController() async {
    if (!controller.value.isInitialized) {
      await controller.initialize();
      setState(() {});
    }
  }

  _loadImage() {
    ImageUtil()
        .getAssetImage("samples/mustashe.png", ImageConfiguration())
        .then((image) {
      overlayImage = image;
    });
  }
}
