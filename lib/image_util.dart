import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageUtil {
  Future<ui.Image> getAssetImage(
      String imageAssets, ImageConfiguration imageConfiguration) async {
    final completer = Completer<ui.Image>();
    Image.asset(imageAssets).image.resolve(imageConfiguration).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));
    return completer.future;
  }
}
