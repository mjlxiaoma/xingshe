import 'package:flutter/services.dart';

class ShareBridgeException implements Exception {
  const ShareBridgeException(this.code, this.message);

  final String code;
  final String message;
}

class ShareBridge {
  ShareBridge()
    : this.testing(
        (path) => const MethodChannel(
          'com.xingshe.app/share',
        ).invokeMethod<void>('shareImage', {'path': path}),
      );

  ShareBridge.testing(this._share);

  final Future<void> Function(String path) _share;

  Future<void> shareImage(String path) async {
    try {
      await _share(path);
    } on PlatformException catch (error) {
      throw ShareBridgeException(error.code, error.message ?? '无法打开系统分享');
    } on ShareBridgeException {
      rethrow;
    } on Object {
      throw const ShareBridgeException('SHARE_CHANNEL_ERROR', '系统分享通道异常');
    }
  }
}
