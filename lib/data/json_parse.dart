/// Разбор полей из хранилища и будущего ответа сервера.
/// Отсутствующее, null и чужой тип не роняют разбор.
Map<String, dynamic> asMap(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

String jsonString(Object? value, [String fallback = '']) {
  if (value is String) {
    return value;
  }
  return fallback;
}

int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

List<int> jsonIds(Object? value) {
  if (value is! List) {
    return const [];
  }
  final result = <int>[];
  for (final item in value) {
    if (item is int) {
      result.add(item);
    } else if (item is num) {
      result.add(item.toInt());
    } else if (item is String) {
      final parsed = int.tryParse(item);
      if (parsed != null) {
        result.add(parsed);
      }
    }
  }
  return result;
}

DateTime? jsonDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? dateToJson(DateTime? value) => value?.toIso8601String();
