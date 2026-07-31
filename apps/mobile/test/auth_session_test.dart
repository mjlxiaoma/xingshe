import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/auth/verification_page.dart';

void main() {
  test('persists, restores, and expires a session', () async {
    final values = <String, String>{};
    final store = TokenStore.testing(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
      delete: (key) async => values.remove(key),
    );
    var container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );

    expect(await container.read(authSessionProvider.future), isFalse);
    await container
        .read(authSessionProvider.notifier)
        .authenticate(
          const SessionTokens(accessToken: 'access', refreshToken: 'refresh'),
        );
    expect(container.read(authSessionProvider).requireValue, isTrue);
    container.dispose();

    container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(await container.read(authSessionProvider.future), isTrue);

    await container.read(authSessionProvider.notifier).expire();
    expect(container.read(authSessionProvider).requireValue, isFalse);
    expect(await store.readTokens(), isNull);
  });

  testWidgets('logs in with a six digit code and saves tokens', (tester) async {
    final values = <String, String>{};
    final store = TokenStore.testing(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
      delete: (key) async => values.remove(key),
    );
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (_, _) => const VerificationPage(email: 'user@example.com'),
        ),
        GoRoute(path: '/me', builder: (_, _) => const Text('profile')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          verifyCodeProvider.overrideWithValue((email, code) async {
            expect(email, 'user@example.com');
            expect(code, '123456');
            return const SessionTokens(
              accessToken: 'access',
              refreshToken: 'refresh',
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('验证并登录'));
    await tester.pumpAndSettle();

    expect(find.text('profile'), findsOneWidget);
    expect((await store.readTokens())?.accessToken, 'access');
    router.dispose();
  });
}
