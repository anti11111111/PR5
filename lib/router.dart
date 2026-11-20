import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/access.dart';
import 'auth/auth_notifier.dart';
import 'models/entity_kind.dart';
import 'screens/catalog_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/record_form_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_screens.dart';

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final public = loc == '/login' || loc == '/register';
      if (!loggedIn && !public) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && public) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register')) {
          return from;
        }
        return '/';
      }
      if (!loggedIn || loc == '/forbidden') {
        return null;
      }
      final role = auth.uiRole;
      String deny() => '/forbidden?from=${Uri.encodeComponent(loc)}';
      if (loc == '/my' && role != Role.reader) {
        return deny();
      }
      if (loc == '/desk' && role != Role.manager) {
        return deny();
      }
      if ((loc == '/users' || loc == '/stats') && role != Role.admin) {
        return deny();
      }
      if (loc.startsWith('/clients') && role != Role.manager) {
        return deny();
      }
      final editing = loc.endsWith('/new') || loc.endsWith('/edit');
      if (editing && role == Role.reader) {
        return deny();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          preview: state.uri.queryParameters['preview'],
          reason: state.uri.queryParameters['reason'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(preview: state.uri.queryParameters['preview']),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => ForbiddenScreen(from: state.uri.queryParameters['from'] ?? '/'),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(preview: state.uri.queryParameters['preview']),
      ),
      GoRoute(path: '/my', builder: (context, state) => const MyReservationsScreen()),
      GoRoute(path: '/desk', builder: (context, state) => const DeskScreen()),
      GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      for (final kind in EntityKind.values)
        GoRoute(
          path: kind.path,
          builder: (context, state) => CatalogListScreen(kind: kind),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => RecordFormScreen(
                kind: kind,
                preview: state.uri.queryParameters['preview'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => RecordDetailScreen(
                kind: kind,
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                preview: state.uri.queryParameters['preview'],
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => RecordFormScreen(
                    kind: kind,
                    id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Страница не найдена')),
        body: Center(child: Text(state.uri.toString())),
      );
    },
  );
}
