import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import 'auth_user.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

class AuthApi {
  AuthApi(this.dio);

  final Dio dio;

  Future<AuthSession> login(String email, String password) {
    return _session(
      () => dio.post<Object>(
        'auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: const {'skipAuth': true}),
      ),
    );
  }

  Future<AuthSession> register(String name, String email, String password) {
    return _session(
      () => dio.post<Object>(
        'auth/register',
        data: {'name': name, 'email': email, 'password': password},
        options: Options(extra: const {'skipAuth': true}),
      ),
    );
  }

  Future<AuthSession> refresh(String refreshToken) {
    return _session(
      () => dio.post<Object>(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      ),
    );
  }

  Future<AuthUser> me() => guard(() async {
    final response = await dio.get<Object>('auth/me');
    final data = _map(response.data);
    return AuthUser.fromJson(data);
  });

  Future<void> logout(String? refreshToken) => guard(() async {
    await dio.post<Object>('auth/logout', data: {'refreshToken': refreshToken});
  });

  Future<AuthSession> _session(Future<Response<Object>> Function() send) => guard(() async {
    final response = await send();
    final data = _map(response.data);
    final user = data['user'];
    return AuthSession(
      accessToken: '${data['accessToken'] ?? ''}',
      refreshToken: '${data['refreshToken'] ?? ''}',
      user: AuthUser.fromJson(user is Map ? _stringMap(user) : const {}),
    );
  });

  Map<String, dynamic> _map(Object? data) => data is Map ? _stringMap(data) : <String, dynamic>{};

  Map<String, dynamic> _stringMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}
