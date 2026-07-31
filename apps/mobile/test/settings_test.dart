import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/settings/settings_pages.dart';

void main() {
  test(
    'logout revokes the refresh token and clears only the session',
    () async {
      final values = <String, String>{};
      final store = TokenStore.testing(
        read: (key) async => values[key],
        write: (key, value) async => values[key] = value,
        delete: (key) async => values.remove(key),
      );
      await store.writeTokens(
        const SessionTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
      String? revoked;
      final container = ProviderContainer(
        overrides: [
        tokenStoreProvider.overrideWithValue(store),
        revokeSessionProvider.overrideWithValue((token) async {
          revoked = token;
          throw Exception('offline');
        }),
        ],
      );
      addTearDown(container.dispose);

    await expectLater(container.read(logoutProvider)(), throwsException);

      expect(revoked, 'refresh');
      expect(await store.readTokens(), isNull);
    },
  );
}
