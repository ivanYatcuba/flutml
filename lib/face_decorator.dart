import 'dart:math';
import 'dart:ui' as ui;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class FaceDecoration extends Decoration {
  final Size absoluteImageSize;
  final List<Face> faces;
  final ui.Image image;
  final aspectRatio;
  final bool isFrontDirection;

  FaceDecoration(this.absoluteImageSize, this.faces, this.image,
      this.aspectRatio, this.isFrontDirection);

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return FaceDetectorPainter(
        absoluteImageSize, faces, image, aspectRatio, isFrontDirection);
  }
}

class FaceDetectorPainter extends BoxPainter {
  final Size absoluteImageSize;
  final List<Face> faces;
  final ui.Image image;
  final aspectRatio;
  final bool isFrontDirection;

  final bool isDebug = false;

  final Paint boundingRectPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.red;

  final Paint eyesLandmarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0
    ..color = Colors.blue;

  final Paint earLandmarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0
    ..color = Colors.amber;

  final Paint cheekLandmarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0
    ..color = Colors.green;

  final Paint mouthLandmarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0
    ..color = Colors.deepPurpleAccent;

  final Paint noseLandmarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0
    ..color = Colors.tealAccent;

  Point center;

  FaceDetectorPainter(this.absoluteImageSize, this.faces, this.image,
      this.aspectRatio, this.isFrontDirection);

  @override
  Future paint(
      Canvas canvas, Offset offset, ImageConfiguration configuration) async {
    if (faces != null && faces.isNotEmpty) {
      center = Point(configuration.size.width / 2 + offset.dx,
          configuration.size.height / 2 + offset.dy);

      final double widthRatio =
          absoluteImageSize.width / configuration.size.width;
      final double heightRatio =
          absoluteImageSize.height / configuration.size.height;

      final double ratio = min(widthRatio, heightRatio);

      final double scaleX = 1 / ratio * aspectRatio;
      final double scaleY = 1 / ratio * aspectRatio;

      if (isDebug) {
        print("@: " + aspectRatio.toString());
        print("s: " +
            absoluteImageSize.width.toString() +
            ":" +
            absoluteImageSize.height.toString());
        print("r: " +
            configuration.size.width.toString() +
            ":" +
            configuration.size.height.toString());
      }

      canvas.save();
      canvas.translate(configuration.size.width / 2 + offset.dx,
          configuration.size.height / 2 + offset.dy);
      if (isFrontDirection) {
        canvas.scale(-1, 1);
      }

      for (Face face in faces) {
        if (isDebug) {
          print("z: " + face.headEulerAngleZ.toString());
          _drawLandmarkPoints(face, offset, scaleX, scaleY, canvas);
          _drawBoundingRect(
              canvas, face, scaleX, offset, scaleY, boundingRectPaint);
        }
        _drawMoustache(face, scaleX, scaleY, offset, canvas);
      }
      canvas.restore();
    }
  }

  void _drawMoustache(Face face, double scaleX, double scaleY, ui.Offset offset,
      ui.Canvas canvas) {
    if (image != null) {
      final aspect = image.height / image.width;

      final double scaleX2 =
          face.boundingBox.width / image.width / 4 / aspect * scaleX;
      final double scaleY2 =
          face.boundingBox.height / image.height / 4 * scaleY;

      final landmarkNose = face.getLandmark(FaceLandmarkType.noseBase);
      final landmarkMouth = face.getLandmark(FaceLandmarkType.bottomMouth);

      if (landmarkNose != null && landmarkMouth != null) {
        final newHeight = image.height.toDouble() * scaleY2;
        final newWidth = image.width.toDouble() * scaleX2;

        final mouthX = landmarkNose.position.x +
            (landmarkMouth.position.x - landmarkNose.position.x) * 1 / 3;

        final mouthY = landmarkNose.position.y +
            (landmarkMouth.position.y - landmarkNose.position.y) * 1 / 3;

        final x = mouthX * scaleX + offset.dx - newWidth / 2 - center.x;
        final y = mouthY * scaleY + offset.dy - newHeight / 2 - center.y;
        var currentRect = Rect.fromLTWH(x, y, newWidth, newHeight);
        final previousRect =
            PreviousPointContainer.singleton.previousDrawRegion;
        if (previousRect != null) {
          final p1 = Point(currentRect.topLeft.dx, currentRect.topLeft.dy);
          final p2 = Point(previousRect.topLeft.dx, previousRect.topLeft.dy);
          final distance = p1.distanceTo(p2);
          if (distance < 10) {
            currentRect = previousRect;
          }
        }

        var src = Rect.fromLTWH(
            0.0, 0.0, image.width.toDouble(), image.height.toDouble());
        var dst = currentRect;
        PreviousPointContainer.singleton.previousDrawRegion = dst;

        canvas.drawImageRect(image, src, dst, boundingRectPaint);
      }
    }
  }

  void _drawBoundingRect(ui.Canvas canvas, Face face, double scaleX,
      ui.Offset offset, double scaleY, ui.Paint paint) {
    canvas.drawRect(
      Rect.fromLTRB(
        ((face.boundingBox.left) * scaleX + offset.dx - center.x),
        ((face.boundingBox.top) * scaleY + offset.dy - center.y),
        ((face.boundingBox.right) * scaleX + offset.dx - center.x),
        ((face.boundingBox.bottom) * scaleY + offset.dy - center.y),
      ),
      paint,
    );
  }

  void _drawLandmarkPoints(Face face, ui.Offset offset, double scaleX,
      double scaleY, ui.Canvas canvas) {
    _addLandmark(
        canvas, FaceLandmarkType.leftEar, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.rightEar, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.leftEye, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.rightEye, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.rightCheek, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.leftCheek, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.rightMouth, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.leftMouth, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.bottomMouth, face, offset, scaleX, scaleY);
    _addLandmark(
        canvas, FaceLandmarkType.noseBase, face, offset, scaleX, scaleY);
  }

  Paint _getLandmarkPaint(FaceLandmarkType landmarkType) {
    switch (landmarkType) {
      case FaceLandmarkType.leftEar:
        return earLandmarkPaint;
      case FaceLandmarkType.rightEar:
        return earLandmarkPaint;
      case FaceLandmarkType.leftEye:
        return eyesLandmarkPaint;
      case FaceLandmarkType.rightEye:
        return eyesLandmarkPaint;
      case FaceLandmarkType.bottomMouth:
        return mouthLandmarkPaint;
      case FaceLandmarkType.rightMouth:
        return mouthLandmarkPaint;
      case FaceLandmarkType.leftMouth:
        return mouthLandmarkPaint;
      case FaceLandmarkType.leftCheek:
        return cheekLandmarkPaint;
      case FaceLandmarkType.rightCheek:
        return cheekLandmarkPaint;
      case FaceLandmarkType.noseBase:
        return noseLandmarkPaint;
    }
    return boundingRectPaint;
  }

  _addLandmark(Canvas canvas, FaceLandmarkType type, Face face, Offset offset,
      double scaleX, double scaleY) {
    final landmark = face.getLandmark(type);
    if (landmark != null) {
      canvas.drawPoints(
          ui.PointMode.points,
          [_pointToOffset(landmark.position, offset, scaleX, scaleY)],
          _getLandmarkPaint(type));
    }
  }

  Offset _pointToOffset(
      Point<double> point, Offset offset, double scaleX, double scaleY) {
    return Offset(point.x * scaleX + offset.dx - center.x,
        point.y * scaleY + offset.dy - center.y);
  }
}

class PreviousPointContainer {
  static final PreviousPointContainer singleton =
  new PreviousPointContainer._internal();

  Rect previousDrawRegion;

  factory PreviousPointContainer() {
    return singleton;
  }

  PreviousPointContainer._internal();
}
