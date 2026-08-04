import 'package:flutter/services.dart';

class CapturedPhoto {
  const CapturedPhoto({required this.uri, required this.takenAt});

  final String uri;
  final DateTime takenAt;

  factory CapturedPhoto.fromMap(Object? value) {
    final map = Map<String, Object?>.from(value as Map);
    final uri = map['uri'] as String;
    if (!uri.startsWith('content://')) {
      throw const FormatException('Unsupported photo URI');
    }
    return CapturedPhoto(
      uri: uri,
      takenAt: DateTime.fromMillisecondsSinceEpoch(
        map['taken_at'] as int,
        isUtc: true,
      ),
    );
  }
}

class MediaBridgeException implements Exception {
  const MediaBridgeException(this.code, this.message);

  final String code;
  final String message;
}

class MediaBridge {
  MediaBridge()
    : this.testing(
        () => const MethodChannel(
          'com.xingshe.app/media',
        ).invokeMethod<Object?>('capturePhoto'),
        () => const MethodChannel(
          'com.xingshe.app/media',
        ).invokeMethod<Object?>('importPhotos'),
      );

  MediaBridge.testing(this._capture, [Future<Object?> Function()? importPhotos])
    : _importPhotos = importPhotos ?? _emptyImport;

  final Future<Object?> Function() _capture;
  final Future<Object?> Function() _importPhotos;

  Future<CapturedPhoto?> capturePhoto() async {
    try {
      final result = await _capture();
      return result == null ? null : CapturedPhoto.fromMap(result);
    } on PlatformException catch (error) {
      throw MediaBridgeException(error.code, error.message ?? '拍照失败');
    } on MediaBridgeException {
      rethrow;
    } on Object {
      throw const MediaBridgeException('MEDIA_CHANNEL_ERROR', '相机通道异常');
    }
  }

  Future<List<CapturedPhoto>> importPhotos() async {
    try {
      final result = await _importPhotos() as List;
      return result
          .map((value) => CapturedPhoto.fromMap(value))
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw MediaBridgeException(error.code, error.message ?? '照片导入失败');
    } on MediaBridgeException {
      rethrow;
    } on Object {
      throw const MediaBridgeException('MEDIA_CHANNEL_ERROR', '系统相册通道异常');
    }
  }
}

Future<Object?> _emptyImport() async => const <Object?>[];
