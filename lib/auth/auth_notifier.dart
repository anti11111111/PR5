import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/config.dart';
import 'access.dart';
import 'auth_api.dart';
import 'auth_user.dart';

/// Сессия на клиенте. Роль в хранилище нужна только чтобы нарисовать интерфейс.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._prefs, this._api, this.tokens);

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';
  static const _kStarted = 'auth_session_started';
  static const _kActivity = 'auth_last_activity';

  final SharedPreferences _prefs;
  final AuthApi _api;
  final TokenBox tokens;

  AuthUser? _user;
  String? message;
  var _refreshing = false;
  Future<bool>? _refreshTask;

  AuthUser? get user => _user;

  bool get isAuthenticated => _user != null && tokens.access != null;

  /// Роль для кнопок читается из localStorage: её можно подменить в DevTools.
  Role get uiRole {
    final raw = _prefs.getString(_kUser);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['role'] is String) {
          return roleOf(decoded['role'] as String);
        }
      } catch (_) {}
    }
    return _user?.asRole ?? Role.reader;
  }

  bool allowsAction(SalonAction action) => isAuthenticated && allows(uiRole, action);

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final rawUser = _prefs.getString(_kUser);
    if (access == null || rawUser == null) {
      return;
    }
    if (_expired(sessionLimit, _kStarted) || _expired(idleTimeout, _kActivity)) {
      message = _expired(sessionLimit, _kStarted)
          ? 'Время сессии истекло. Войдите снова.'
          : 'Сессия завершена из-за неактивности.';
      await _clear();
      return;
    }
    tokens.access = access;
    _user = _readUser(rawUser);
    try {
      final fresh = await _api.me();
      _user = _user?.copyWith() ?? fresh;
      _user = AuthUser(id: fresh.id, name: fresh.name, email: fresh.email, role: _user!.role);
      await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    } on UnauthorizedException {
      final refresh = _prefs.getString(_kRefresh);
      if (refresh == null || !await this.refresh()) {
        await _clear();
      }
    } on ApiException catch (error) {
      message = error.message;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final session = await _api.login(email.trim(), password);
    await _store(session);
  }

  Future<void> register(String name, String email, String password) async {
    final session = await _api.register(name.trim(), email.trim(), password);
    await _store(session);
  }

  Future<bool> refresh() {
    if (_refreshing && _refreshTask != null) {
      return _refreshTask!;
    }
    _refreshing = true;
    _refreshTask = _refresh().whenComplete(() {
      _refreshing = false;
      _refreshTask = null;
    });
    return _refreshTask!;
  }

  Future<bool> _refresh() async {
    final token = _prefs.getString(_kRefresh);
    if (token == null) {
      return false;
    }
    try {
      final session = await _api.refresh(token);
      await _store(session, keepStart: true);
      return true;
    } on ApiException {
      await logout();
      return false;
    }
  }

  /// Подмена роли только в браузере. Токен и роль на сервере не меняются.
  Future<void> tamperRole(String role) async {
    if (_user == null) {
      return;
    }
    _user = _user!.copyWith(role: role);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    final refresh = _prefs.getString(_kRefresh);
    try {
      if (tokens.access != null) {
        await _api.logout(refresh);
      }
    } catch (_) {}
    await _clear();
    notifyListeners();
  }

  void touch() {
    _prefs.setInt(_kActivity, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _store(AuthSession session, {bool keepStart = false}) async {
    tokens.access = session.accessToken;
    _user = session.user;
    message = null;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_kAccess, session.accessToken);
    await _prefs.setString(_kRefresh, session.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(session.user.toJson()));
    await _prefs.setInt(_kActivity, now);
    if (!keepStart || !_prefs.containsKey(_kStarted)) {
      await _prefs.setInt(_kStarted, now);
    }
    notifyListeners();
  }

  Future<void> _clear() async {
    tokens.access = null;
    _user = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kStarted);
    await _prefs.remove(_kActivity);
  }

  bool _expired(Duration limit, String key) {
    final stamp = _prefs.getInt(key);
    if (stamp == null) {
      return false;
    }
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(stamp)) > limit;
  }

  AuthUser? _readUser(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AuthUser.fromJson(decoded.map((key, value) => MapEntry('$key', value)));
      }
    } catch (_) {}
    return null;
  }
}
