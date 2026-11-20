class PasswordCheck {
  const PasswordCheck(this.password);

  final String password;

  bool get longEnough => password.length >= 8;
  bool get hasDigit => RegExp(r'\d').hasMatch(password);
  bool get hasSpecial => RegExp(r'[^A-Za-zА-Яа-яЁё0-9]').hasMatch(password);
  bool get valid => longEnough && hasDigit && hasSpecial;

  String? get message {
    if (password.isEmpty) {
      return 'Введите пароль';
    }
    if (!longEnough) {
      return 'Пароль должен быть не короче 8 символов';
    }
    if (!hasDigit) {
      return 'Добавьте хотя бы одну цифру';
    }
    if (!hasSpecial) {
      return 'Добавьте специальный символ';
    }
    return null;
  }
}
