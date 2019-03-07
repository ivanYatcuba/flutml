import 'package:flutml/presentation/home_page.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection Sample',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[800],
        accentColor: Colors.cyan[600],
      ),
      home: CameraPage(title: 'Mustache decorator'),
    );
  }
}

Future<void> main() async {
  runApp(MyApp());
}
