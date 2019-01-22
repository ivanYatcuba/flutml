import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File imageFile;
  Size imageSize;
  List<Face> faces;

  _MyHomePageState({this.imageFile, this.imageSize, this.faces});

  @override
  Widget build(BuildContext context) {
    if (imageFile != null && faces == null) {
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(
            child: Image.file(imageFile),
          ));
    }

    if (imageFile != null && faces != null) {
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: _buildImage());
    }
    _loadImage();
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(child: Text("Loading...")));
  }

  Widget _buildImage() {
    return Center(
        child: Container(
            foregroundDecoration: FaceDecoration(imageSize, faces),
            child: Image.file(imageFile)));
  }

  Future<List<Face>> getSample() async {
    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);
    final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(
            enableLandmarks: true,
            enableClassification: true,
            enableTracking: false,
            mode: FaceDetectorMode.accurate));

    return await faceDetector.detectInImage(visionImage);
  }

  _loadImage() {
    _writeBruce().then((bruceFile) {
      _getImageSize(bruceFile).then((size) {
        setState(() {
          imageFile = bruceFile;
          imageSize = size;
        });
        getSample().then((results) {
          setState(() {
            faces = results;
          });
        });
      });
    });
  }

  Future<Size> _getImageSize(File imageFile) async {
    final completer = new Completer<Size>();
    Image.file(imageFile).image.resolve(new ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble())));
    return completer.future;
  }

  Future<File> _writeBruce() async {
    final directory = await getTemporaryDirectory();
    final path = directory.path;
    final file = File('$path/sample.jpg');
    final bytes = await rootBundle.load('samples/donald.jpg');
    return file.writeAsBytes(bytes.buffer.asUint8List());
  }
}

class FaceDecoration extends Decoration {
  final Size absoluteImageSize;
  final List<Face> faces;

  FaceDecoration(this.absoluteImageSize, this.faces);

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new FaceDetectorPainter(absoluteImageSize, faces);
  }
}

class FaceDetectorPainter extends BoxPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.faces);

  final Size absoluteImageSize;
  final List<Face> faces;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size;
    final double scaleX = rect.width / absoluteImageSize.width;
    final double scaleY = rect.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final Paint paintLandmark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = Colors.blue;

    for (Face face in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          face.boundingBox.left * scaleX + offset.dx,
          face.boundingBox.top * scaleY + offset.dy,
          face.boundingBox.right * scaleX + offset.dx,
          face.boundingBox.bottom * scaleY + offset.dy,
        ),
        paint,
      );
      List<Offset> points = List();
      _addLandmark(
          FaceLandmarkType.leftEar, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.rightEar, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.leftEye, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.rightEar, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.rightCheek, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.leftCheek, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.rightMouth, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.leftMouth, points, face, offset, scaleX, scaleY);
      _addLandmark(
          FaceLandmarkType.bottomMouth, points, face, offset, scaleX, scaleY);

      canvas.drawPoints(PointMode.points, points, paintLandmark);
    }
  }

  _addLandmark(FaceLandmarkType type, List<Offset> points, Face face,
      Offset offset, double scaleX, double scaleY) {
    final landmark = face.getLandmark(type);
    if (landmark != null) {
      points.add(_pointToOffset(landmark.position, offset, scaleX, scaleY));
    }
  }

  Offset _pointToOffset(
      Point<double> point, Offset offset, double scaleX, double scaleY) {
    return Offset(point.x * scaleX + offset.dx, point.y * scaleY + offset.dy);
  }
}
