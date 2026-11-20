import '../data/json_parse.dart';
import 'driver_license.dart';

class Client {
  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.license,
    this.deletedAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DriverLicense license;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  String get fullName => '$firstName $lastName'.trim();

  Client copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DriverLicense? license,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      license: license ?? this.license,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'license': license.toJson(),
    'deletedAt': dateToJson(deletedAt),
  };

  factory Client.fromJson(Map<String, dynamic> json) {
    final map = asMap(json);
    return Client(
      id: jsonInt(map['id']),
      firstName: jsonString(map['firstName']),
      lastName: jsonString(map['lastName']),
      email: jsonString(map['email']),
      phone: jsonString(map['phone']),
      license: DriverLicense.fromJson(map['license']),
      deletedAt: jsonDate(map['deletedAt']),
    );
  }

  Map<String, Object?> toForm() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'licenseNumber': license.number,
    'issuedOn': _day(license.issuedOn),
    'expiresOn': _day(license.expiresOn),
  };

  static String _day(DateTime? value) {
    if (value == null) {
      return '';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
