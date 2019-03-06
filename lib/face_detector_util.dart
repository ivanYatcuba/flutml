import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class DetectorResult {
  final Size imageSize;
  final List<Face> faces;

  DetectorResult(this.imageSize, this.faces);
}

class FaceDetectorUtil {
  final faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: false,
      enableTracking: true,
      mode: FaceDetectorMode.accurate));

  bool isDetectingAlready = false;

  Future<DetectorResult> getSample(CameraImage cameraImage,
      CameraLensDirection cameraDirection) async {
    if (isDetectingAlready) {
      return null;
    }

    isDetectingAlready = true;
    final planeData = cameraImage.planes
        .map((plane) => FirebaseVisionImagePlaneMetadata(
            width: cameraImage.width,
            height: cameraImage.height,
            bytesPerRow: plane.bytesPerRow))
        .toList();

    final int numBytes = cameraImage.planes
        .fold(0, (count, plane) => count += plane.bytes.length);
    final Uint8List allBytes = Uint8List(numBytes);

    int nextIndex = 0;
    for (int i = 0; i < cameraImage.planes.length; i++) {
      allBytes.setRange(
          nextIndex,
          nextIndex + cameraImage.planes[i].bytes.length,
          cameraImage.planes[i].bytes);
      nextIndex += cameraImage.planes[i].bytes.length;
    }

    ImageRotation rotation;
    if (cameraDirection == CameraLensDirection.front) {
      rotation = ImageRotation.rotation270;
    } else {
      rotation = ImageRotation.rotation90;
    }

    FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rawFormat: cameraImage.format.raw,
        rotation: rotation,
        planeData: planeData);

    final visionImage = FirebaseVisionImage.fromBytes(allBytes, metadata);

    final faces = await faceDetector.detectInImage(visionImage);
    isDetectingAlready = false;
    return DetectorResult(
        Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        faces);
  }
}
