import '../data/json_parse.dart';

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.foundedYear,
    required this.bodyTypeIds,
    required this.optionIds,
    this.carCount = 0,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String country;
  final int foundedYear;

  /// Кузова и опции, которые предлагает марка. От них сужаются списки в форме машины.
  final List<int> bodyTypeIds;
  final List<int> optionIds;
  final int carCount;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Brand copyWith({
    int? id,
    String? name,
    String? country,
    int? foundedYear,
    List<int>? bodyTypeIds,
    List<int>? optionIds,
    int? carCount,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      foundedYear: foundedYear ?? this.foundedYear,
      bodyTypeIds: bodyTypeIds ?? this.bodyTypeIds,
      optionIds: optionIds ?? this.optionIds,
      carCount: carCount ?? this.carCount,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'foundedYear': foundedYear,
    'bodyTypeIds': bodyTypeIds,
    'optionIds': optionIds,
    'cars': carCount,
    'deletedAt': dateToJson(deletedAt),
  };

  factory Brand.fromJson(Map<String, dynamic> json) {
    final map = asMap(json);
    return Brand(
      id: jsonInt(map['id']),
      name: jsonString(map['name']),
      country: jsonString(map['country']),
      foundedYear: jsonInt(map['foundedYear']),
      bodyTypeIds: jsonIds(map['bodyTypeIds']),
      optionIds: jsonIds(map['optionIds']),
      carCount: jsonInt(map['cars']),
      deletedAt: jsonDate(map['deletedAt']),
    );
  }

  Map<String, Object?> toForm() => {
    'name': name,
    'country': country,
    'foundedYear': foundedYear == 0 ? '' : '$foundedYear',
    'bodyTypeIds': [...bodyTypeIds],
    'optionIds': [...optionIds],
  };
}
