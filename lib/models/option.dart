import '../data/json_parse.dart';

class Option {
  const Option({
    required this.id,
    required this.name,
    required this.description,
    this.carCount = 0,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String description;
  final int carCount;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Option copyWith({
    int? id,
    String? name,
    String? description,
    int? carCount,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Option(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      carCount: carCount ?? this.carCount,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cars': carCount,
    'deletedAt': dateToJson(deletedAt),
  };

  factory Option.fromJson(Map<String, dynamic> json) {
    final map = asMap(json);
    return Option(
      id: jsonInt(map['id']),
      name: jsonString(map['name']),
      description: jsonString(map['description']),
      carCount: jsonInt(map['cars']),
      deletedAt: jsonDate(map['deletedAt']),
    );
  }

  Map<String, Object?> toForm() => {'name': name, 'description': description};
}
