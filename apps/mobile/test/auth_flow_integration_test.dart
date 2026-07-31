import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/api/api_client.dart';
import 'package:xingshe/core/api/api_providers.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/auth/email_login_page.dart';
import 'package:xingshe/features/auth/verification_page.dart';
import 'package:xingshe/features/settings/settings_pages.dart';

void main() {
  test('authentication flow handles login errors restore and logout', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      final body = request.contentLength == 0
          ? <String, dynamic>{}
          : jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/auth/email-code')) {
        expect(body['email'], 'user@example.com');
        request.response.write(_response(<String, dynamic>{}));
      } else if (request.uri.path.endsWith('/auth/login')) {
        if (body['code'] != '123456') {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(
            jsonEncode({
              'code': 'AUTH_1002',
              'message': '验证码不正确',
              'data': null,
            }),
          );
        } else {
          request.response.write(
            _response({
              'access_token': 'access',
              'refresh_token': 'refresh',
              'expires_in': 900,
            }),
          );
        }
      } else if (request.uri.path.endsWith('/auth/logout')) {
        expect(body['refresh_token'], 'refresh');
        request.response.write(_response(<String, dynamic>{}));
      }
      await request.response.close();
    });

    final values = <String, String>{};
    final store = TokenStore.testing(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
      delete: (key) async => values.remove(key),
    );
    ProviderContainer makeContainer() {
      late ProviderContainer container;
      container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWith(
            (_) => ApiClient(
              tokenStore: store,
              baseURL: 'http://${server.address.host}:${server.port}/api/v1',
              onSessionExpired: () =>
                  container.read(authSessionProvider.notifier).expire(),
            ),
          ),
        ],
      );
      return container;
    }

    var container = makeContainer();
    expect(await container.read(authSessionProvider.future), isFalse);
    expect(
      await container
          .read(emailCodeRequestProvider.notifier)
          .send('USER@EXAMPLE.COM'),
      isTrue,
    );
    await expectLater(
      container.read(verifyCodeProvider)('user@example.com', '000000'),
      throwsA(
        isA<ApiException>().having((error) => error.code, 'code', 'AUTH_1002'),
      ),
    );
    final tokens = await container.read(verifyCodeProvider)(
      'user@example.com',
      '123456',
    );
    await container.read(authSessionProvider.notifier).authenticate(tokens);
    expect(container.read(authSessionProvider).requireValue, isTrue);
    container.dispose();

    container = makeContainer();
    expect(await container.read(authSessionProvider.future), isTrue);
    await container.read(logoutProvider)();
    expect(container.read(authSessionProvider).requireValue, isFalse);
    expect(await store.readTokens(), isNull);
    container.dispose();
  });
}

String _response(Object data) =>
    jsonEncode({'code': 'OK', 'message': 'success', 'data': data});
