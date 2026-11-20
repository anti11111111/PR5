import '../data/json_parse.dart';

/// Водительское удостоверение. Отдельного списка нет: оно живёт внутри клиента.
class DriverLicense {
  const DriverLicense({
    required this.number,
    this.issuedOn,
    this.expiresOn,
  });

  final String number;
  final DateTime? issuedOn;
  final DateTime? expiresOn;

  Map<String, dynamic> toJson() => {
    'number': number,
    'issuedOn': dateToJson(issuedOn),
    'expiresOn': dateToJson(expiresOn),
  };

  factory DriverLicense.fromJson(Object? json) {
    final map = asMap(json);
    return DriverLicense(
      number: jsonString(map['number']),
      issuedOn: jsonDate(map['issuedOn']),
      expiresOn: jsonDate(map['expiresOn']),
    );
  }
}
