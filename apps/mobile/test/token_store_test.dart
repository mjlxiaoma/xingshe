import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/token_store.dart';

void main() {
  test(
    'stores session securely while retaining the device ID on logout',
    () async {
      final values = <String, String>{};
      final store = TokenStore.testing(
        read: (key) async => values[key],
        write: (key, value) async => values[key] = value,
        delete: (key) async => values.remove(key),
      );

      expect(await store.readTokens(), isNull);
      final deviceID = await store.deviceID();
      expect(await store.deviceID(), deviceID);

      await store.writeTokens(
        const SessionTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
      final tokens = await store.readTokens();
      expect(tokens?.accessToken, 'access');
      expect(tokens?.refreshToken, 'refresh');

      await store.clearTokens();
      expect(await store.readTokens(), isNull);
      expect(await store.deviceID(), deviceID);
    },
  );
}
