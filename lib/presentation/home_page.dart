import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutml/face_decorator.dart';
import 'package:flutml/face_detector_util.dart';
import 'package:flutml/image_util.dart';
import 'package:flutml/presentation/image_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CameraPage extends StatefulWidget {
  CameraPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImageUtil imageUtil = ImageUtil();
  final faceDetector = FaceDetectorUtil();

  List<CameraDescription> cameras;

  List<Face> faces;
  ui.Image overlayImage;
  Size imageSize;

  CameraLensDirection cameraLensDirection = CameraLensDirection.back;
  CameraController controller;
  bool streamInitialized = false;
  bool isDisposed = false;

  _CameraPageState({this.faces});

  @override
  void initState() {
    super.initState();
    imageUtil.loadOverlayImage().then((image) {
      setState(() {
        overlayImage = image;
      });
    });
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null ||
        isDisposed == true ||
        !controller.value.isInitialized ||
        !mounted) {
      return Scaffold(appBar: _getAppBar(), body: _getLoadingView());
    } else {
      SchedulerBinding.instance
          .addPostFrameCallback((_) =>
      {
      _initializeVideoStream()
      });
      return Scaffold(
        appBar: _getAppBar(),
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.max,
          verticalDirection: VerticalDirection.up,
          children: <Widget>[
            Expanded(
              child: Container(
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    _switchCamera();
                  },
                  child: _getFabIcon(),
                ),
              ),
            ),
            Expanded(
              child: FloatingActionButton(
                heroTag: null,
                child: Icon(
                  Icons.camera,
                ),
                onPressed: () async {
                  await _takePicture();
                },
              ),
            ),
          ],
        ),
        body: _getCameraPreviewWidget(),
      );
    }
  }

  Widget _getAppBar() {
    return AppBar(
      title: Text(widget.title),
    );
  }

  Widget _getLoadingView() {
    return Center(child: CircularProgressIndicator());
  }

  _takePicture() async {
    //todo ios support
    final directory = await getExternalStorageDirectory();
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    try {
      final picturePath = directory.path + "/" + Uuid().v1() + ".jpg";
      await controller.takePicture(picturePath);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) =>
              ImagePreview(filePath: picturePath)));
    } catch (e) {}

    streamInitialized = false;
  }

  Widget _getCameraPreviewWidget() {
    return Center(
        child: Container(
            foregroundDecoration: FaceDecoration(
                imageSize,
                faces,
                overlayImage,
                controller.value.aspectRatio,
                cameraLensDirection == CameraLensDirection.front),
            child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller))));
  }

  Icon _getFabIcon() {
    if (cameraLensDirection == CameraLensDirection.front) {
      return Icon(Icons.camera_rear);
    } else {
      return Icon(Icons.camera_front);
    }
  }

  _switchCamera() {
    if (cameraLensDirection == CameraLensDirection.front) {
      cameraLensDirection = CameraLensDirection.back;
    } else {
      cameraLensDirection = CameraLensDirection.front;
    }
    setState(() {
      isDisposed = true;
    });
    _initializeCamera().then((_) {
      setState(() {
        streamInitialized = false;
        isDisposed = false;
      });
    });
  }

  Future _initializeCamera() async {
    PreviousPointContainer.singleton.previousDrawRegion = null;
    if (controller?.value?.isStreamingImages == true) {
      await controller?.stopImageStream();
    }
    await controller?.dispose();

    final cameras = await availableCameras();

    final camera = cameras
        .firstWhere((camera) => camera.lensDirection == cameraLensDirection);

    controller = CameraController(camera, ResolutionPreset.low);

    await controller.initialize();
  }

  void _initializeVideoStream() {
    if (streamInitialized == false) {
      streamInitialized = true;
      controller.startImageStream((imageData) async {
        final faces =
        await faceDetector.getSample(imageData, cameraLensDirection);
        if (faces != null) {
          setState(() {
            this.imageSize = faces.imageSize;
            this.faces = faces.faces;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
