import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/features/share/share_bridge.dart';

void main() {
  test('shares one image and normalizes platform failures', () async {
    String? sharedPath;
    await ShareBridge.testing(
      (path) async => sharedPath = path,
    ).shareImage('cache/xingshe_share/trip.png');
    expect(sharedPath, 'cache/xingshe_share/trip.png');

    final failing = ShareBridge.testing(
      (_) async => throw PlatformException(
        code: 'SHARE_UNAVAILABLE',
        message: 'unavailable',
      ),
    );
    await expectLater(
      failing.shareImage('cache/xingshe_share/trip.png'),
      throwsA(
        isA<ShareBridgeException>().having(
          (error) => error.code,
          'code',
          'SHARE_UNAVAILABLE',
        ),
      ),
    );
  });

  test('Android FileProvider is private and cache scoped', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();
    final paths = await File(
      'android/app/src/main/res/xml/share_paths.xml',
    ).readAsString();
    final bridge = await File(
      'android/app/src/main/kotlin/com/xingshe/app/ShareBridge.kt',
    ).readAsString();

    expect(
      manifest,
      contains('android:name="androidx.core.content.FileProvider"'),
    );
    expect(manifest, contains('android:exported="false"'));
    expect(manifest, contains('android:grantUriPermissions="true"'));
    expect(paths, contains('path="xingshe_share/"'));
    expect(paths, isNot(contains('<external-path')));
    expect(bridge, contains('FileProvider.getUriForFile'));
    expect(bridge, contains('Intent.FLAG_GRANT_READ_URI_PERMISSION'));
    expect(bridge, isNot(contains('Uri.fromFile')));
  });
}
