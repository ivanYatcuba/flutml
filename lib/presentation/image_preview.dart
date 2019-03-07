import 'dart:io';

import 'package:flutter/widgets.dart';

class ImagePreview extends StatelessWidget {
  final String filePath;

  const ImagePreview({Key key, this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.file(File(filePath));
  }
}
