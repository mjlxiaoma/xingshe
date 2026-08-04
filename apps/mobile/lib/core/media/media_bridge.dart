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
        (uri, maxSize) => const MethodChannel('com.xingshe.app/media')
            .invokeMethod<Uint8List>('loadPhoto', {
              'uri': uri,
              'max_size': maxSize,
            }),
        (uri) => const MethodChannel(
          'com.xingshe.app/media',
        ).invokeMethod<void>('deletePhoto', {'uri': uri}),
      );

  MediaBridge.testing(
    this._capture, [
    Future<Object?> Function()? importPhotos,
    Future<Uint8List?> Function(String, int)? loadPhoto,
    Future<void> Function(String)? deletePhoto,
  ]) : _importPhotos = importPhotos ?? _emptyImport,
       _loadPhoto = loadPhoto ?? _emptyPhoto,
       _deletePhoto = deletePhoto ?? _emptyDelete;

  final Future<Object?> Function() _capture;
  final Future<Object?> Function() _importPhotos;
  final Future<Uint8List?> Function(String, int) _loadPhoto;
  final Future<void> Function(String) _deletePhoto;

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

  Future<Uint8List> loadPhoto(String uri, {int maxSize = 512}) async {
    if (!uri.startsWith('content://')) {
      throw const MediaBridgeException('MEDIA_INVALID_URI', '不支持的照片地址');
    }
    try {
      final bytes = await _loadPhoto(uri, maxSize.clamp(64, 2048));
      if (bytes == null || bytes.isEmpty) {
        throw const MediaBridgeException('MEDIA_READ_FAILED', '照片读取失败');
      }
      return bytes;
    } on PlatformException catch (error) {
      throw MediaBridgeException(error.code, error.message ?? '照片读取失败');
    } on MediaBridgeException {
      rethrow;
    } on Object {
      throw const MediaBridgeException('MEDIA_CHANNEL_ERROR', '照片读取通道异常');
    }
  }

  Future<void> deletePhoto(String uri) async {
    if (!uri.startsWith('content://')) {
      throw const MediaBridgeException('MEDIA_INVALID_URI', '不支持的照片地址');
    }
    try {
      await _deletePhoto(uri);
    } on PlatformException catch (error) {
      throw MediaBridgeException(error.code, error.message ?? '系统相册原图删除失败');
    } on MediaBridgeException {
      rethrow;
    } on Object {
      throw const MediaBridgeException('MEDIA_CHANNEL_ERROR', '照片删除通道异常');
    }
  }
}

Future<Object?> _emptyImport() async => const <Object?>[];
Future<Uint8List?> _emptyPhoto(String _, int _) async => null;
Future<void> _emptyDelete(String _) async {}
