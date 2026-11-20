import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_api/core/api_client.dart';
import 'package:salon_api/core/api_exceptions.dart';
import 'package:salon_api/models/car.dart';
import 'package:salon_api/repositories/api_repository.dart';

void main() {
  Dio build(Future<ResponseBody> Function(RequestOptions options) handler, {required _Probe probe}) {
    final dio = buildDio(baseUrl: 'http://localhost:8080/api/');
    dio.httpClientAdapter = _ProbeAdapter(handler, probe);
    return dio;
  }

  ResponseBody json(int status, Object body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  test('страница автомобилей разбирается из ответа сервера', () async {
    final probe = _Probe();
    final repo = ApiRepository(
      build((options) async {
        expect(options.uri.path, '/api/cars');
        expect(options.queryParameters['page'], '2');
        return json(200, {
          'items': [
            {
              'id': 1,
              'model': 'Supra',
              'vin': 'XTA000001',
              'year': 2020,
              'brandId': 1,
              'bodyTypeId': 5,
              'optionIds': [1],
            },
          ],
          'page': 2,
          'size': 10,
          'total': 24,
        });
      }, probe: probe),
      'cars',
      Car.fromJson,
    );
    final page = await repo.find({'page': '2', 'size': '10', 'sort': 'model,asc'});
    expect(page.total, 24);
    expect(page.page, 2);
    expect(page.items.single.model, 'Supra');
    expect(probe.calls, 1);
  });

  test('код 422 становится ошибкой поля', () async {
    final repo = ApiRepository(
      build((_) async {
        return json(422, {
          'message': 'Ошибка валидации',
          'errors': {'vin': 'Такой VIN уже записан в каталоге'},
        });
      }, probe: _Probe()),
      'cars',
      Car.fromJson,
    );
    expect(
      () => repo.create({'vin': 'XTA000001'}),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.errors['vin'],
          'vin',
          'Такой VIN уже записан в каталоге',
        ),
      ),
    );
  });

  test('код 409 становится конфликтом', () async {
    final repo = ApiRepository(
      build((_) async => json(409, {'message': 'Нельзя удалить марку «Toyota»: на неё ссылаются 3 автомобиля.'}), probe: _Probe()),
      'brands',
      Car.fromJson,
    );
    expect(
      () => repo.softDelete(1),
      throwsA(isA<ConflictException>().having((error) => error.message, 'message', contains('3 автомобиля'))),
    );
  });

  test('нет соединения превращается в подсказку про CORS', () async {
    final repo = ApiRepository(
      build((options) async {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      }, probe: _Probe()),
      'cars',
      Car.fromJson,
    );
    expect(
      () => repo.find(const {}),
      throwsA(isA<NetworkException>().having((error) => error.message, 'message', contains('CORS'))),
    );
  });

  test('чтение повторяется три раза, создание — один', () async {
    final readProbe = _Probe();
    var reads = 0;
    final readRepo = ApiRepository(
      build((options) async {
        reads++;
        if (reads < 3) {
          throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
        }
        return json(200, {'items': [], 'page': 1, 'size': 10, 'total': 0});
      }, probe: readProbe),
      'cars',
      Car.fromJson,
    );
    final page = await readRepo.find(const {});
    expect(page.total, 0);
    expect(readProbe.calls, 3);

    final writeProbe = _Probe();
    final writeRepo = ApiRepository(
      build((options) async {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      }, probe: writeProbe),
      'cars',
      Car.fromJson,
    );
    await expectLater(writeRepo.create({'model': 'Повтор'}), throwsA(isA<NetworkException>()));
    expect(writeProbe.calls, 1);
  });

  test('код 401 становится требованием входа', () async {
    final repo = ApiRepository(
      build((_) async => json(401, {'message': 'Требуется вход в систему.'}), probe: _Probe()),
      'cars',
      Car.fromJson,
    );
    expect(() => repo.readOne(1), throwsA(isA<UnauthorizedException>()));
  });
}

class _Probe {
  var calls = 0;
}

class _ProbeAdapter implements HttpClientAdapter {
  _ProbeAdapter(this.handler, this.probe);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final _Probe probe;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    probe.calls++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
