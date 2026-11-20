import 'package:flutter_test/flutter_test.dart';
import 'package:salon_api/auth/access.dart';

void main() {
  test('читатель смотрит каталог и продлевает свою бронь', () {
    expect(allows(Role.reader, SalonAction.viewCatalog), isTrue);
    expect(allows(Role.reader, SalonAction.extendOwn), isTrue);
  });

  test('читатель не управляет пользователями и не удаляет записи', () {
    expect(allows(Role.reader, SalonAction.manageUsers), isFalse);
    expect(allows(Role.reader, SalonAction.hardDelete), isFalse);
    expect(allows(Role.reader, SalonAction.editCatalog), isFalse);
  });

  test('менеджер ведёт стойку, клиентов и каталог', () {
    expect(allows(Role.manager, SalonAction.manageDesk), isTrue);
    expect(allows(Role.manager, SalonAction.manageClients), isTrue);
    expect(allows(Role.manager, SalonAction.editCatalog), isTrue);
  });

  test('менеджеру закрыты статистика, пользователи и чужие брони', () {
    expect(allows(Role.manager, SalonAction.viewStats), isFalse);
    expect(allows(Role.manager, SalonAction.manageUsers), isFalse);
    expect(allows(Role.manager, SalonAction.extendOwn), isFalse);
  });

  test('администратор удаляет навсегда, смотрит статистику и пользователей', () {
    expect(allows(Role.admin, SalonAction.hardDelete), isTrue);
    expect(allows(Role.admin, SalonAction.restoreRecords), isTrue);
    expect(allows(Role.admin, SalonAction.viewStats), isTrue);
    expect(allows(Role.admin, SalonAction.manageUsers), isTrue);
  });

  test('у администратора нет стойки менеджера и личных броней читателя', () {
    expect(allows(Role.admin, SalonAction.manageDesk), isFalse);
    expect(allows(Role.admin, SalonAction.manageClients), isFalse);
    expect(allows(Role.admin, SalonAction.extendOwn), isFalse);
  });

  test('повтор токена не запускается для входа и для уже повторённого запроса', () {
    expect(shouldRefresh('auth/login', 401, retried: false), isFalse);
    expect(shouldRefresh('cars', 401, retried: true), isFalse);
    expect(shouldRefresh('cars', 401, retried: false), isTrue);
    expect(shouldRefresh('cars', 403, retried: false), isFalse);
  });
}
