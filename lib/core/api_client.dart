import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/access.dart';
import 'api_exceptions.dart';
import 'config.dart';

/// Токен живёт здесь, интерсептор читает его на каждый запрос.
class TokenBox {
  String? access;
  Future<bool> Function()? refresh;

  String? get value => access;
}

Dio buildDio({TokenBox? tokens, String? baseUrl}) {
  late final Dio dio;
  dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? apiBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Content-Type': 'application/json'},
      // Коды 4xx не бросают исключение сами: их разбирает интерсептор.
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens?.access;
        if (token != null && options.extra['skipAuth'] != true) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('[API] ← ${response.requestOptions.method} ${response.requestOptions.uri} $status');
        }
        if (status >= 400) {
          // throw внутри интерсептора Dio завернёт в DioException с типом unknown.
          // Поэтому отказ отправляем сами и кладём уже разобранное исключение в error.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        final options = error.requestOptions;
        final retried = options.extra['retried'] == true;
        if (shouldRefresh(options.path, error.response?.statusCode, retried: retried) &&
            tokens?.refresh != null) {
          final ok = await tokens!.refresh!();
          if (ok && tokens.access != null) {
            options.extra['retried'] = true;
            options.headers['Authorization'] = 'Bearer ${tokens.access}';
            try {
              final response = await dio.fetch<Object>(options);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
}
