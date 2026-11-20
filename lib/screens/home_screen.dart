import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../models/entity_kind.dart';
import '../widgets/inactivity_watcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.preview});

  final String? preview;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final role = auth.uiRole;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Автосалон'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Выйти',
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.directions_car, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'Каталог автосалона',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user == null ? 'Вход не выполнен' : '${user.name}, роль: ${roleLabel(role)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(_hint(role), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  for (final kind in EntityKind.values)
                    if (kind != EntityKind.client || role == Role.manager) ...[
                      SizedBox(
                        width: double.infinity,
                        child: kind == EntityKind.car
                            ? FilledButton.icon(
                                onPressed: () => context.go(kind.path),
                                icon: const Icon(Icons.directions_car),
                                label: Text(kind.title),
                              )
                            : FilledButton.tonalIcon(
                                onPressed: () => context.go(kind.path),
                                icon: Icon(_icon(kind)),
                                label: Text(kind.title),
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  if (role == Role.reader)
                    _link(context, '/my', Icons.bookmark, 'Мои брони'),
                  if (role == Role.manager)
                    _link(context, '/desk', Icons.support_agent, 'Стойка менеджера'),
                  if (role == Role.admin) ...[
                    _link(context, '/users', Icons.group, 'Пользователи'),
                    _link(context, '/stats', Icons.bar_chart, 'Статистика'),
                  ],
                ],
              ),
            ),
          ),
          if (preview == 'idle') IdleWarning(onContinue: () {}),
        ],
      ),
    );
  }

  String _hint(Role role) => switch (role) {
    Role.reader => 'Читатель смотрит каталог и продлевает свои брони. Кнопок изменения нет.',
    Role.manager => 'Менеджер ведёт каталог, клиентов и стойку броней. Пользователей он не видит.',
    Role.admin => 'Администратор управляет пользователями, смотрит статистику и удаляет записи навсегда.',
  };

  Widget _link(BuildContext context, String path, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: () => context.go(path),
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  IconData _icon(EntityKind kind) => switch (kind) {
    EntityKind.car => Icons.directions_car,
    EntityKind.brand => Icons.factory,
    EntityKind.bodyType => Icons.airport_shuttle,
    EntityKind.option => Icons.tune,
    EntityKind.client => Icons.badge,
  };
}
