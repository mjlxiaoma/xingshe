import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<File> generateTripShareImage(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
    throw StateError('Share card is not ready');
  }
  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('PNG encoding failed');
    return writeTripSharePng(data.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Future<File> writeTripSharePng(Uint8List bytes) async {
  final directory = await Directory.systemTemp.createTemp('xingshe_share_');
  return File(
    '${directory.path}${Platform.pathSeparator}trip.png',
  ).writeAsBytes(bytes, flush: true);
}
