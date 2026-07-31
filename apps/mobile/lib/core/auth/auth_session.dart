import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

final authSessionProvider = AsyncNotifierProvider<AuthSessionController, bool>(
  AuthSessionController.new,
);

class AuthSessionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      await ref.read(tokenStoreProvider).readTokens() != null;

  Future<void> authenticate(SessionTokens tokens) async {
    await future;
    await ref.read(tokenStoreProvider).writeTokens(tokens);
    state = const AsyncData(true);
  }

  Future<void> expire() async {
    await future;
    await ref.read(tokenStoreProvider).clearTokens();
    state = const AsyncData(false);
  }
}
