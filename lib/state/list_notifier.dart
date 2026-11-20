import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'load_status.dart';

class Slice<T> {
  ListQuery query = const ListQuery();
  PageResult<T> result = PageResult<T>.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  Object? failure;
  final Set<int> selected = {};
  var ticket = 0;
  CancelToken? cancel;
}

/// Четыре состояния списка: загрузка, данные, пустой результат и ошибка.
/// Пустой результат — это успешный ответ с total == 0, его рисует экран.
class ListLoader {
  Future<void> load<T>({
    required Slice<T> slice,
    required ListQuery query,
    required Future<PageResult<T>> Function(ListQuery query, CancelToken cancel) find,
    required VoidCallback notify,
    bool force = false,
  }) async {
    if (!force && slice.query == query && slice.status == LoadStatus.success && slice.cancel == null) {
      return;
    }
    slice.cancel?.cancel();
    final cancel = CancelToken();
    slice.cancel = cancel;
    slice.query = query;
    slice.selected.clear();
    final ticket = ++slice.ticket;
    slice.status = LoadStatus.loading;
    slice.error = null;
    slice.failure = null;
    notify();
    try {
      final result = await find(query, cancel);
      if (ticket != slice.ticket) {
        return;
      }
      slice.result = result;
      slice.status = LoadStatus.success;
    } on CancelledException {
      return;
    } catch (error) {
      if (ticket != slice.ticket) {
        return;
      }
      slice.failure = error;
      slice.error = error is ApiException ? error.message : '$error';
      slice.status = LoadStatus.error;
    }
    slice.cancel = null;
    notify();
  }
}
