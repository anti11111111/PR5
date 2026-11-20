import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../data/catalog_cache.dart';
import '../models/body_type.dart';
import '../models/brand.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/option.dart';
import '../models/page_result.dart';
import '../models/session.dart';
import 'api_repository.dart';

/// Вход и справочники. Списки сущностей лежат в [ApiRepository].
class SalonApi {
  SalonApi(this.dio)
    : cars = ApiRepository(dio, 'cars', Car.fromJson),
      brands = ApiRepository(dio, 'brands', Brand.fromJson),
      bodies = ApiRepository(dio, 'body-types', BodyType.fromJson),
      options = ApiRepository(dio, 'options', Option.fromJson),
      clients = ApiRepository(dio, 'clients', Client.fromJson);

  final Dio dio;
  final ApiRepository<Car> cars;
  final ApiRepository<Brand> brands;
  final ApiRepository<BodyType> bodies;
  final ApiRepository<Option> options;
  final ApiRepository<Client> clients;

  Future<Session> login(String email, String password, TokenBox tokens) {
    return guard(() async {
      final response = await dio.post<Object>(
        'auth/login',
        data: {'email': email, 'password': password},
      );
      final data = _map(response.data);
      final token = data['accessToken'] ?? data['token'];
      tokens.access = token is String ? token : null;
      final user = data['user'];
      return Session.fromJson(user is Map ? _stringMap(user) : const {});
    });
  }

  /// Марки, кузова и опции для выпадающих списков. Повторно не запрашиваются.
  Future<void> warm(CatalogCache cache) async {
    if (cache.ready) {
      return;
    }
    final pages = await Future.wait<Object>([
      brands.find({'page': '1', 'size': '100', 'sort': 'name,asc'}),
      bodies.find({'page': '1', 'size': '100', 'sort': 'name,asc'}),
      options.find({'page': '1', 'size': '100', 'sort': 'name,asc'}),
    ]);
    cache.replace(
      brands: (pages[0] as PageResult<Brand>).items,
      bodyTypes: (pages[1] as PageResult<BodyType>).items,
      options: (pages[2] as PageResult<Option>).items,
    );
  }

  Future<Car> reserve(int id) {
    return guard(() async {
      final response = await dio.post<Object>('cars/$id/reserve');
      return Car.fromJson(_map(response.data));
    });
  }

  Map<String, dynamic> _map(Object? data) => data is Map ? _stringMap(data) : <String, dynamic>{};

  Map<String, dynamic> _stringMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}
