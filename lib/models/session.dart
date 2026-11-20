class Session {
  const Session({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  String get roleLabel => switch (role) {
    'admin' => 'администратор',
    'manager' => 'менеджер',
    'viewer' => 'наблюдатель',
    _ => role,
  };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      name: json['name'] is String ? json['name'] as String : '',
      email: json['email'] is String ? json['email'] as String : '',
      role: json['role'] is String ? json['role'] as String : '',
    );
  }
}
