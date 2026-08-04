import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/api/api_client.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/core/observability/error_reporter.dart';

void main() {
  test('refreshes once on 401 and retries with the new access token', () async {
    var resourceRequests = 0;
    var refreshRequests = 0;
    Map<String, dynamic>? refreshPayload;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/v1/auth/refresh') {
        refreshRequests++;
        refreshPayload =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.write(
          jsonEncode({
            'code': 'OK',
            'message': 'success',
            'data': {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'expires_in': 7200,
            },
          }),
        );
      } else {
        resourceRequests++;
        if (request.headers.value(HttpHeaders.authorizationHeader) ==
            'Bearer new-access') {
          request.response.write(
            jsonEncode({
              'code': 'OK',
              'message': 'success',
              'data': {'value': 42},
            }),
          );
        } else {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(
            jsonEncode({
              'code': 'AUTH_INVALID_TOKEN',
              'message': 'expired',
              'data': null,
            }),
          );
        }
      }
      await request.response.close();
    });
    final memory = <String, String>{};
    final store = memoryStore(memory);
    await store.writeTokens(
      const SessionTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      ),
    );
    final client = ApiClient(
      tokenStore: store,
      baseURL: 'http://${server.address.host}:${server.port}/api/v1',
    );

    final value = await client.request<int>(
      '/resource',
      decode: (data) => (data as Map<String, dynamic>)['value'] as int,
    );

    expect(value, 42);
    expect(resourceRequests, 2);
    expect(refreshRequests, 1);
    expect(refreshPayload?['refresh_token'], 'old-refresh');
    expect(refreshPayload?['device_id'], isNotEmpty);
    expect((await store.readTokens())?.refreshToken, 'new-refresh');
  });

  test(
    'clears the session and reports a unified error when refresh fails',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'code': 'AUTH_INVALID_TOKEN',
            'message': 'expired',
            'data': null,
          }),
        );
        await request.response.close();
      });
      final memory = <String, String>{};
      final store = memoryStore(memory);
      await store.writeTokens(
        const SessionTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
      var expired = false;
      final reports = <({AppErrorEvent event, String? code, int? status})>[];
      final client = ApiClient(
        tokenStore: store,
        baseURL: 'http://${server.address.host}:${server.port}/api/v1',
        onSessionExpired: () => expired = true,
        errorReporter: (event, {code, status}) =>
            reports.add((event: event, code: code, status: status)),
      );

      await expectLater(
        client.request<Object?>('/resource', decode: (data) => data),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'AUTH_INVALID_TOKEN',
          ),
        ),
      );
      expect(expired, isTrue);
      expect(await store.readTokens(), isNull);
      expect(reports.map((report) => report.event), [
        AppErrorEvent.sessionRefreshFailed,
        AppErrorEvent.apiRequestFailed,
      ]);
      expect(reports.last.code, 'AUTH_INVALID_TOKEN');
      expect(reports.every((report) => report.status == 401), isTrue);
    },
  );
}

TokenStore memoryStore(Map<String, String> values) {
  return TokenStore.testing(
    read: (key) async => values[key],
    write: (key, value) async => values[key] = value,
    delete: (key) async => values.remove(key),
  );
}
