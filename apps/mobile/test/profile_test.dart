import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/profile/profile_page.dart';

void main() {
  test('loads and updates the signed-in profile', () async {
    final store = TokenStore.testing(
      read: (key) async => key.contains('access') ? 'access' : 'refresh',
      write: (_, _) async {},
      delete: (_) async {},
    );
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        loadProfileProvider.overrideWithValue(
          () async => const UserProfile(
            id: '1',
            email: 'user@example.com',
            nickname: '行摄者',
          ),
        ),
        updateProfileProvider.overrideWithValue(
          (nickname) async => UserProfile(
            id: '1',
            email: 'user@example.com',
            nickname: nickname,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect((await container.read(profileProvider.future))?.nickname, '行摄者');
    expect(
      await container.read(profileProvider.notifier).updateNickname('新昵称'),
      isTrue,
    );
    expect(container.read(profileProvider).requireValue?.nickname, '新昵称');
    expect(
      await container.read(profileProvider.notifier).updateNickname(' '),
      isFalse,
    );
  });
}
