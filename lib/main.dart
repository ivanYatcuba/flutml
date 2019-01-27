import 'package:camera/camera.dart';
import 'package:flutml/presentation/home_page.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(MyApp());
}