import 'access.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  Role get asRole => roleOf(role);

  AuthUser copyWith({String? role}) {
    return AuthUser(id: id, name: name, email: email, role: role ?? this.role);
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] is String ? json['name'] as String : '',
      email: json['email'] is String ? json['email'] as String : '',
      role: json['role'] is String ? json['role'] as String : 'reader',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role};
}
