import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:xingshe/core/api/api_client.dart';
import 'package:xingshe/core/api/api_providers.dart';
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

  test('account deletion sends DELETE and clears the session', () async {
    final adapter = _DeleteAccountAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final values = <String, String>{};
    final store = TokenStore.testing(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
      delete: (key) async => values.remove(key),
    );
    await store.writeTokens(
      const SessionTokens(accessToken: 'access', refreshToken: 'refresh'),
    );
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (_) => ApiClient(
            tokenStore: store,
            baseURL: 'https://example.invalid/api/v1',
            dio: dio,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(authSessionProvider.future), isTrue);

    expect(await container.read(deleteAccountProvider)(false), isTrue);

    expect(adapter.deleted, isTrue);
    expect(await store.readTokens(), isNull);
    expect(container.read(authSessionProvider).requireValue, isFalse);
  });

  testWidgets(
    'account deletion defaults to retaining trips and shows all states',
    (tester) async {
      final deletion = Completer<bool>();
      bool? clearLocalTrips;
      final router = GoRouter(
        initialLocation: '/delete',
        routes: [
          GoRoute(
            path: '/delete',
            builder: (_, _) => const AccountDeletionPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('未登录状态')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deleteAccountProvider.overrideWithValue((clear) {
              clearLocalTrips = clear;
              return deletion.future;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.textContaining('系统相册原图不会自动删除'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-local-trips-option')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-deletion-submit')));
      await tester.pumpAndSettle();
      expect(find.text('确认永久删除账号？'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-account-deletion')));
      await tester.pump();
      expect(clearLocalTrips, isTrue);
      expect(
        find.byKey(const Key('account-deletion-progress')),
        findsOneWidget,
      );

      deletion.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('account-deletion-success')), findsOneWidget);
      await tester.tap(find.byKey(const Key('finish-account-deletion')));
      await tester.pumpAndSettle();
      expect(find.text('未登录状态'), findsOneWidget);
    },
  );

  testWidgets('account deletion failure remains retryable', (tester) async {
    final router = GoRouter(
      initialLocation: '/delete',
      routes: [
        GoRoute(
          path: '/delete',
          builder: (_, _) => const AccountDeletionPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deleteAccountProvider.overrideWithValue(
            (_) async => throw const ApiException(
              code: 'NETWORK_ERROR',
              message: 'offline',
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account-deletion-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account-deletion-error')), findsOneWidget);
    expect(find.text('重试删除'), findsOneWidget);
    expect(find.byKey(const Key('cancel-account-deletion')), findsOneWidget);
  });
}

class _DeleteAccountAdapter implements HttpClientAdapter {
  bool deleted = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    deleted =
        options.method == 'DELETE' &&
        options.uri.path.endsWith('/api/v1/me') &&
        options.headers['Authorization'] == 'Bearer access';
    return ResponseBody.fromString(
      jsonEncode({'code': 'OK', 'message': 'success', 'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
