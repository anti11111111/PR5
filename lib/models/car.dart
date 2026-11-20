import '../data/json_parse.dart';

/// Автомобиль в каталоге. [deletedAt] прячет машину с продажи, не стирая её.
class Car {
  const Car({
    required this.id,
    required this.model,
    required this.vin,
    required this.year,
    required this.mileage,
    required this.brandId,
    required this.bodyTypeId,
    required this.optionIds,
    required this.horsepower,
    required this.price,
    required this.inStock,
    required this.stockTotal,
    this.deletedAt,
  });

  final int id;
  final String model;
  final String vin;
  final int year;
  final int mileage;
  final int brandId;
  final int bodyTypeId;
  final List<int> optionIds;
  final int horsepower;
  final int price;
  final int inStock;
  final int stockTotal;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Car copyWith({
    int? id,
    String? model,
    String? vin,
    int? year,
    int? mileage,
    int? brandId,
    int? bodyTypeId,
    List<int>? optionIds,
    int? horsepower,
    int? price,
    int? inStock,
    int? stockTotal,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Car(
      id: id ?? this.id,
      model: model ?? this.model,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      brandId: brandId ?? this.brandId,
      bodyTypeId: bodyTypeId ?? this.bodyTypeId,
      optionIds: optionIds ?? this.optionIds,
      horsepower: horsepower ?? this.horsepower,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
      stockTotal: stockTotal ?? this.stockTotal,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'model': model,
    'vin': vin,
    'year': year,
    'mileage': mileage,
    'brandId': brandId,
    'bodyTypeId': bodyTypeId,
    'optionIds': optionIds,
    'horsepower': horsepower,
    'price': price,
    'inStock': inStock,
    'stockTotal': stockTotal,
    'deletedAt': dateToJson(deletedAt),
  };

  factory Car.fromJson(Map<String, dynamic> json) {
    final map = asMap(json);
    return Car(
      id: jsonInt(map['id']),
      model: jsonString(map['model']),
      vin: jsonString(map['vin']),
      year: jsonInt(map['year']),
      mileage: jsonInt(map['mileage']),
      brandId: jsonInt(map['brandId']),
      bodyTypeId: jsonInt(map['bodyTypeId']),
      optionIds: jsonIds(map['optionIds']),
      horsepower: jsonInt(map['horsepower']),
      price: jsonInt(map['price']),
      inStock: jsonInt(map['inStock']),
      stockTotal: jsonInt(map['stockTotal']),
      deletedAt: jsonDate(map['deletedAt']),
    );
  }

  Map<String, Object?> toForm() => {
    'model': model,
    'vin': vin,
    'year': year == 0 ? '' : '$year',
    'mileage': '$mileage',
    'brandId': brandId == 0 ? null : brandId,
    'bodyTypeId': bodyTypeId == 0 ? null : bodyTypeId,
    'optionIds': [...optionIds],
    'horsepower': horsepower == 0 ? '' : '$horsepower',
    'price': price == 0 ? '' : '$price',
    'stockTotal': stockTotal == 0 ? '' : '$stockTotal',
    'inStock': '$inStock',
  };
}
