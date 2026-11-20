String normalizeVin(String value) =>
    value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

String? requiredText(
  String? value, {
  required String label,
  int min = 1,
  int max = 200,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Заполните поле «$label»';
  }
  if (text.length < min) {
    return '«$label» короче $min символов';
  }
  if (text.length > max) {
    return '«$label» длиннее $max символов';
  }
  return null;
}

String? optionalText(String? value, {required String label, int max = 200}) {
  final text = value?.trim() ?? '';
  if (text.length > max) {
    return '«$label» длиннее $max символов';
  }
  return null;
}

String? intInRange(
  String? value, {
  required String label,
  required int min,
  required int max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Укажите поле «$label»';
  }
  final parsed = int.tryParse(text);
  if (parsed == null) {
    return '«$label» должно быть целым числом';
  }
  if (parsed < min || parsed > max) {
    return '«$label» должно быть от $min до $max';
  }
  return null;
}

String? vinFormat(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Укажите VIN';
  }
  if (text.length > 17) {
    return 'VIN не длиннее 17 символов';
  }
  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(text)) {
    return 'VIN состоит из латинских букв и цифр';
  }
  if (text.length < 6) {
    return 'VIN короче 6 символов';
  }
  return null;
}

String? phoneFormat(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Укажите телефон';
  }
  if (text.length < 10 || text.length > 18) {
    return 'Телефон от 10 до 18 символов';
  }
  if (!RegExp(r'^[0-9+\-() ]+$').hasMatch(text)) {
    return 'Телефон состоит из цифр, пробелов и +';
  }
  return null;
}

String? emailFormat(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Укажите почту';
  }
  if (text.length > 80) {
    return 'Почта не длиннее 80 символов';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Почта должна быть вида имя@домен.зона';
  }
  return null;
}

String? dateText(String? value, {required String label}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Укажите $label';
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    return 'Дата в формате ГГГГ-ММ-ДД';
  }
  return null;
}

String? requiredChoice(int? value, String message) => value == null ? message : null;

String? requiredIds(List<int> value, String message) => value.isEmpty ? message : null;

/// «1 автомобиль», «2 автомобиля», «5 автомобилей».
String carsPhrase(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  final word = (mod10 == 1 && mod100 != 11)
      ? 'автомобиль'
      : (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14))
      ? 'автомобиля'
      : 'автомобилей';
  final verb = count == 1 ? 'ссылается' : 'ссылаются';
  return 'на неё $verb $count $word';
}
