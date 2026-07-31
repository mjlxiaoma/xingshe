import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef SecureRead = Future<String?> Function(String key);
typedef SecureWrite = Future<void> Function(String key, String value);
typedef SecureDelete = Future<void> Function(String key);

class SessionTokens {
  const SessionTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : this._fromStorage(storage ?? const FlutterSecureStorage());

  TokenStore._fromStorage(FlutterSecureStorage storage)
    : this.testing(
        read: (key) => storage.read(key: key),
        write: (key, value) => storage.write(key: key, value: value),
        delete: (key) => storage.delete(key: key),
      );

  TokenStore.testing({
    required SecureRead read,
    required SecureWrite write,
    required SecureDelete delete,
  }) : this._(read, write, delete);

  TokenStore._(this._read, this._write, this._delete);

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _deviceKey = 'auth_device_id';

  final SecureRead _read;
  final SecureWrite _write;
  final SecureDelete _delete;

  Future<SessionTokens?> readTokens() async {
    final accessToken = await _read(_accessKey);
    final refreshToken = await _read(_refreshKey);
    if (accessToken == null && refreshToken == null) return null;
    if (accessToken == null || refreshToken == null) {
      await clearTokens();
      return null;
    }
    return SessionTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> writeTokens(SessionTokens tokens) async {
    await _write(_refreshKey, tokens.refreshToken);
    await _write(_accessKey, tokens.accessToken);
  }

  Future<void> clearTokens() async {
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  Future<String> deviceID() async {
    final existing = await _read(_deviceKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final generated = base64Url.encode(bytes).replaceAll('=', '');
    await _write(_deviceKey, generated);
    return generated;
  }
}
