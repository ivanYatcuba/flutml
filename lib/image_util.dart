import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageUtil {
  Future<ui.Image> loadOverlayImage() async {
    return _getAssetImage("samples/mustashe.png", ImageConfiguration());
  }

  Future<ui.Image> _getAssetImage(
      String imageAssets, ImageConfiguration imageConfiguration) async {
    final completer = Completer<ui.Image>();
    Image.asset(imageAssets).image.resolve(imageConfiguration).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));
    return completer.future;
  }
}
