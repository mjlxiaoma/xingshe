import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import '../observability/error_reporter.dart';

class ApiConfig {
  static const baseURL = String.fromEnvironment(
    'MOBILE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );
}

class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status});

  final String code;
  final String message;
  final int? status;

  factory ApiException.fromDio(DioException error) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return ApiException(
        code: payload['code'] as String? ?? 'NETWORK_ERROR',
        message: payload['message'] as String? ?? '请求失败',
        status: error.response?.statusCode,
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: error.type == DioExceptionType.connectionTimeout
          ? '网络连接超时'
          : '网络连接失败',
      status: error.response?.statusCode,
    );
  }

  @override
  String toString() => '$code: $message';
}

class ApiClient {
  ApiClient({
    required this.tokenStore,
    String baseURL = ApiConfig.baseURL,
    Dio? dio,
    Dio? refreshDio,
    this.onSessionExpired,
    ErrorReporter? errorReporter,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseURL)),
       _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseURL)),
       _errorReporter = errorReporter ?? reportErrorSafely {
    _dio.options
      ..baseUrl = baseURL
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15);
    _refreshDio.options
      ..baseUrl = baseURL
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokens = await tokenStore.readTokens();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: _handleError,
      ),
    );
  }

  final TokenStore tokenStore;
  final Dio _dio;
  final Dio _refreshDio;
  final ErrorReporter _errorReporter;
  final void Function()? onSessionExpired;

  Future<T> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? data) decode,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      final envelope = response.data;
      if (envelope == null || envelope['code'] != 'OK') {
        throw ApiException(
          code: envelope?['code'] as String? ?? 'INVALID_RESPONSE',
          message: envelope?['message'] as String? ?? '响应格式不正确',
          status: response.statusCode,
        );
      }
      return decode(envelope['data']);
    } on ApiException catch (error) {
      _report(
        AppErrorEvent.apiRequestFailed,
        code: error.code,
        status: error.status,
      );
      rethrow;
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);
      _report(
        AppErrorEvent.apiRequestFailed,
        code: exception.code,
        status: exception.status,
      );
      throw exception;
    } on Object {
      _report(AppErrorEvent.apiRequestFailed, code: 'INVALID_RESPONSE');
      rethrow;
    }
  }

  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 || request.extra['retried'] == true) {
      handler.next(error);
      return;
    }
    final tokens = await tokenStore.readTokens();
    if (tokens != null) {
      try {
        final sentToken = _bearerToken(request.headers['Authorization']);
        if (sentToken == tokens.accessToken) {
          final response = await _refreshDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {
              'refresh_token': tokens.refreshToken,
              'device_id': await tokenStore.deviceID(),
            },
          );
          final data = response.data?['data'];
          if (data is! Map<String, dynamic>) throw const FormatException();
          await tokenStore.writeTokens(
            SessionTokens(
              accessToken: data['access_token'] as String,
              refreshToken: data['refresh_token'] as String,
            ),
          );
        }
        final current = await tokenStore.readTokens();
        if (current != null) {
          request.headers['Authorization'] = 'Bearer ${current.accessToken}';
          request.extra['retried'] = true;
          handler.resolve(await _dio.fetch(request));
          return;
        }
      } catch (_) {
        _report(
          AppErrorEvent.sessionRefreshFailed,
          status: error.response?.statusCode,
        );
        // The original 401 is returned after clearing the unusable session.
      }
    }
    await tokenStore.clearTokens();
    onSessionExpired?.call();
    handler.next(error);
  }

  void _report(AppErrorEvent event, {String? code, int? status}) {
    try {
      _errorReporter(event, code: code, status: status);
    } on Object {
      // Error reporting must never interrupt the user flow.
    }
  }

  String? _bearerToken(Object? header) {
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }
}
