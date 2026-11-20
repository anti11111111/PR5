import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../models/page_result.dart';

/// Общий доступ к одной сущности. Поиск, страница и сортировка уходят на сервер.
class ApiRepository<T> {
  ApiRepository(this._dio, this.path, this.decode);

  final Dio _dio;
  final String path;
  final T Function(Map<String, dynamic>) decode;

  Future<PageResult<T>> find(
    Map<String, String> query, {
    CancelToken? cancel,
    bool debugFlags = false,
  }) {
    return _read(() async {
      final response = await _dio.get<Object>(
        path,
        queryParameters: {
          ...query,
          if (debugFlags && ShotFlags.delayMs > 0) '__delay': '${ShotFlags.delayMs}',
          if (debugFlags && ShotFlags.failCode != null) '__fail': '${ShotFlags.failCode}',
        },
        cancelToken: cancel,
      );
      final data = _map(response.data);
      final items = data['items'];
      return PageResult(
        items: [
          for (final item in items is List ? items : const [])
            if (item is Map) decode(_stringMap(item)),
        ],
        page: _int(data['page'], 1),
        size: _int(data['size'], 10),
        total: _int(data['total'], 0),
      );
    });
  }

  Future<T> readOne(int id, {CancelToken? cancel}) {
    return _read(() async {
      final response = await _dio.get<Object>('$path/$id', cancelToken: cancel);
      return decode(_map(response.data));
    });
  }

  Future<T> create(Map<String, dynamic> body) => guard(() async {
    final response = await _dio.post<Object>(path, data: body);
    return decode(_map(response.data));
  });

  Future<T> update(int id, Map<String, dynamic> body) => guard(() async {
    final response = await _dio.put<Object>('$path/$id', data: body);
    return decode(_map(response.data));
  });

  Future<void> softDelete(int id) => guard(() async {
    await _dio.delete<Object>('$path/$id');
  });

  Future<void> hardDelete(int id) => guard(() async {
    await _dio.delete<Object>('$path/$id', queryParameters: {'hard': true});
  });

  Future<T> restore(int id) => guard(() async {
    final response = await _dio.post<Object>('$path/$id/restore');
    return decode(_map(response.data));
  });

  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post<Object>('$path/bulk-delete', data: {'ids': ids});
    return _int(_map(response.data)['deleted'], 0);
  });

  /// Повторяем только чтение. Создание повторять нельзя: на сервере появятся дубликаты.
  Future<R> _read<R>(Future<R> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return await guard(action);
      } on CancelledException {
        rethrow;
      } on NetworkException {
        attempt++;
        if (attempt >= maxReadAttempts) {
          rethrow;
        }
        await Future<void>.delayed(retryDelays[attempt - 1]);
      }
    }
  }

  Map<String, dynamic> _map(Object? data) => data is Map ? _stringMap(data) : <String, dynamic>{};

  Map<String, dynamic> _stringMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  int _int(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }
}
