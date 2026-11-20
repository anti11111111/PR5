/// Три роли с разным набором действий, а не с разным объёмом одного и того же.
enum Role { reader, manager, admin }

enum SalonAction {
  viewCatalog,
  extendOwn,
  manageDesk,
  manageClients,
  editCatalog,
  hardDelete,
  restoreRecords,
  manageUsers,
  viewStats,
}

Role roleOf(String? name) => switch (name) {
  'admin' => Role.admin,
  'manager' => Role.manager,
  _ => Role.reader,
};

String roleName(Role role) => switch (role) {
  Role.reader => 'reader',
  Role.manager => 'manager',
  Role.admin => 'admin',
};

String roleLabel(Role role) => switch (role) {
  Role.reader => 'читатель',
  Role.manager => 'менеджер',
  Role.admin => 'администратор',
};

/// Решение «показать кнопку». Настоящий запрет делает сервер по подписанному токену.
bool allows(Role role, SalonAction action) {
  return switch (role) {
    Role.reader => action == SalonAction.viewCatalog || action == SalonAction.extendOwn,
    Role.manager =>
      action == SalonAction.viewCatalog ||
          action == SalonAction.manageDesk ||
          action == SalonAction.manageClients ||
          action == SalonAction.editCatalog,
    Role.admin =>
      action == SalonAction.viewCatalog ||
          action == SalonAction.editCatalog ||
          action == SalonAction.hardDelete ||
          action == SalonAction.restoreRecords ||
          action == SalonAction.manageUsers ||
          action == SalonAction.viewStats,
  };
}

/// Повтор токена нельзя запускать для самого входа: иначе 401 зациклится.
bool shouldRefresh(String path, int? status, {required bool retried}) {
  if (retried || status != 401) {
    return false;
  }
  return !path.contains('auth/');
}
