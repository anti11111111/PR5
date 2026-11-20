/// Адрес сервера задаётся при сборке, а не константой в коде.
///
/// flutter run -d chrome --web-port=5560 --dart-define=API_BASE_URL=http://127.0.0.1:8081/api/
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8081/api/',
);

/// Токен доступа живёт 15 минут, если сервер не запущен с другим --ttl.
const accessTokenTtl = Duration(minutes: 15);

/// Общая длительность сессии не зависит от активности.
const sessionLimit = Duration(hours: 8);

/// Выход, если человек ничего не делает.
const idleTimeout = Duration(minutes: 3);

/// Предупреждение за 30 секунд до выхода по неактивности.
const idleWarning = Duration(seconds: 30);

const connectTimeout = Duration(seconds: 10);
const receiveTimeout = Duration(seconds: 15);

/// Пауза перед следующей попыткой чтения: 200 мс, затем 400 мс.
const retryDelays = [Duration(milliseconds: 200), Duration(milliseconds: 400)];

/// Сколько раз всего читаем список, включая первую попытку.
const maxReadAttempts = 3;

/// Параметры снимков. Сервер их понимает: __delay держит ответ, __fail отдаёт код.
class ShotFlags {
  static int delayMs = 0;
  static int? failCode;
}
