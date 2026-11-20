import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../data/catalog_cache.dart';
import '../models/body_type.dart';
import '../models/brand.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/entity_kind.dart';
import '../models/list_query.dart';
import '../models/option.dart';
import '../models/page_result.dart';
import '../repositories/salon_api.dart';
import 'list_notifier.dart';

/// Экраны ходят сюда. Про Dio они не знают.
class CatalogController extends ChangeNotifier {
  CatalogController(this.store, this.api);

  final CatalogCache store;
  final SalonApi api;
  final _loader = ListLoader();

  final cars = Slice<Car>();
  final brands = Slice<Brand>();
  final bodyTypes = Slice<BodyType>();
  final options = Slice<Option>();
  final clients = Slice<Client>();

  final _cars = <int, Car>{};
  final _brands = <int, Brand>{};
  final _bodies = <int, BodyType>{};
  final _options = <int, Option>{};
  final _clients = <int, Client>{};

  String? get notice => store.notice;

  SessionView get session => SessionView(store.session?.name ?? '', store.session?.roleLabel ?? '');

  Slice<Object?> slice(EntityKind kind) => switch (kind) {
    EntityKind.car => cars,
    EntityKind.brand => brands,
    EntityKind.bodyType => bodyTypes,
    EntityKind.option => options,
    EntityKind.client => clients,
  };

  Future<void> apply(EntityKind kind, ListQuery query, {bool force = false}) {
    return switch (kind) {
      EntityKind.car => _load(cars, query, api.cars.find, (item) => _cars[item.id] = item, force: force),
      EntityKind.brand => _load(brands, query, api.brands.find, (item) => _brands[item.id] = item, force: force),
      EntityKind.bodyType => _load(
        bodyTypes,
        query,
        api.bodies.find,
        (item) => _bodies[item.id] = item,
        force: force,
      ),
      EntityKind.option => _load(options, query, api.options.find, (item) => _options[item.id] = item, force: force),
      EntityKind.client => _load(clients, query, api.clients.find, (item) => _clients[item.id] = item, force: force),
    };
  }

  Future<void> reload(EntityKind kind) => apply(kind, slice(kind).query, force: true);

  void replaceSelection(EntityKind kind, Iterable<int> ids) {
    final selected = slice(kind).selected;
    final next = ids.toSet();
    if (selected.length == next.length && selected.containsAll(next)) {
      return;
    }
    selected
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void toggle(EntityKind kind, int id) {
    final selected = slice(kind).selected;
    if (!selected.add(id)) {
      selected.remove(id);
    }
    notifyListeners();
  }

  Future<int> deleteSelected(EntityKind kind) async {
    final ids = slice(kind).selected.toList();
    final removed = switch (kind) {
      EntityKind.car => await api.cars.deleteMany(ids),
      EntityKind.brand => await api.brands.deleteMany(ids),
      EntityKind.bodyType => await api.bodies.deleteMany(ids),
      EntityKind.option => await api.options.deleteMany(ids),
      EntityKind.client => await api.clients.deleteMany(ids),
    };
    slice(kind).selected.clear();
    await reload(kind);
    return removed;
  }

  Future<String?> softDelete(EntityKind kind, int id) async {
    try {
      switch (kind) {
        case EntityKind.car:
          await api.cars.softDelete(id);
        case EntityKind.brand:
          await api.brands.softDelete(id);
        case EntityKind.bodyType:
          await api.bodies.softDelete(id);
        case EntityKind.option:
          await api.options.softDelete(id);
        case EntityKind.client:
          await api.clients.softDelete(id);
      }
    } on ConflictException catch (error) {
      return error.message;
    }
    await reload(kind);
    return null;
  }

  Future<String?> hardDelete(EntityKind kind, int id) async {
    try {
      switch (kind) {
        case EntityKind.car:
          await api.cars.hardDelete(id);
        case EntityKind.brand:
          await api.brands.hardDelete(id);
        case EntityKind.bodyType:
          await api.bodies.hardDelete(id);
        case EntityKind.option:
          await api.options.hardDelete(id);
        case EntityKind.client:
          await api.clients.hardDelete(id);
      }
    } on ConflictException catch (error) {
      return error.message;
    } on ForbiddenException catch (error) {
      return error.message;
    }
    await reload(kind);
    return null;
  }

  Future<void> restore(EntityKind kind, int id) async {
    switch (kind) {
      case EntityKind.car:
        _cars[id] = await api.cars.restore(id);
      case EntityKind.brand:
        _brands[id] = await api.brands.restore(id);
      case EntityKind.bodyType:
        _bodies[id] = await api.bodies.restore(id);
      case EntityKind.option:
        _options[id] = await api.options.restore(id);
      case EntityKind.client:
        _clients[id] = await api.clients.restore(id);
    }
    await reload(kind);
  }

  Future<int> saveForm(EntityKind kind, int? id, Map<String, Object?> values) async {
    final saved = switch (kind) {
      EntityKind.car => await _saveCar(id, values),
      EntityKind.brand => await _saveBrand(id, values),
      EntityKind.bodyType => await _saveBody(id, values),
      EntityKind.option => await _saveOption(id, values),
      EntityKind.client => await _saveClient(id, values),
    };
    store.ready = false;
    try {
      await api.warm(store);
    } on ApiException {
      store.notice = 'Запись сохранена, но справочники не обновились.';
    }
    return saved;
  }

  Future<void> fetch(EntityKind kind, int id) async {
    switch (kind) {
      case EntityKind.car:
        _cars[id] = await api.cars.readOne(id);
      case EntityKind.brand:
        _brands[id] = await api.brands.readOne(id);
      case EntityKind.bodyType:
        _bodies[id] = await api.bodies.readOne(id);
      case EntityKind.option:
        _options[id] = await api.options.readOne(id);
      case EntityKind.client:
        _clients[id] = await api.clients.readOne(id);
    }
    notifyListeners();
  }

  Future<Car> reserve(int id) async {
    final car = await api.reserve(id);
    _cars[id] = car;
    notifyListeners();
    return car;
  }

  Map<String, Object?>? formOf(EntityKind kind, int id) {
    return switch (kind) {
      EntityKind.car => _cars[id]?.toForm(),
      EntityKind.brand => _brands[id]?.toForm(),
      EntityKind.bodyType => _bodies[id]?.toForm(),
      EntityKind.option => _options[id]?.toForm(),
      EntityKind.client => _clients[id]?.toForm(),
    };
  }

  String? titleOf(EntityKind kind, int id) {
    return switch (kind) {
      EntityKind.car => _cars[id]?.model,
      EntityKind.brand => _brands[id]?.name,
      EntityKind.bodyType => _bodies[id]?.name,
      EntityKind.option => _options[id]?.name,
      EntityKind.client => _clients[id]?.fullName,
    };
  }

  bool isDeleted(EntityKind kind, int id) {
    return switch (kind) {
      EntityKind.car => _cars[id]?.isDeleted ?? false,
      EntityKind.brand => _brands[id]?.isDeleted ?? false,
      EntityKind.bodyType => _bodies[id]?.isDeleted ?? false,
      EntityKind.option => _options[id]?.isDeleted ?? false,
      EntityKind.client => _clients[id]?.isDeleted ?? false,
    };
  }

  List<(String, String)> details(EntityKind kind, int id) {
    return switch (kind) {
      EntityKind.car => _carDetails(id),
      EntityKind.brand => _brandDetails(id),
      EntityKind.bodyType => _bodyDetails(id),
      EntityKind.option => _optionDetails(id),
      EntityKind.client => _clientDetails(id),
    };
  }

  Future<void> _load<T>(
    Slice<T> slice,
    ListQuery query,
    Future<PageResult<T>> Function(Map<String, String> query, {CancelToken? cancel, bool debugFlags}) find,
    void Function(T item) remember, {
    required bool force,
  }) {
    return _loader.load<T>(
      slice: slice,
      query: query,
      notify: notifyListeners,
      force: force,
      find: (next, cancel) async {
        final page = await find(next.toParams(), cancel: cancel, debugFlags: true);
        for (final item in page.items) {
          remember(item);
        }
        return page;
      },
    );
  }

  Future<int> _saveCar(int? id, Map<String, Object?> values) async {
    final body = {
      'model': _text(values, 'model'),
      'vin': _text(values, 'vin'),
      'year': int.parse(_text(values, 'year')),
      'mileage': int.parse(_text(values, 'mileage')),
      'brandId': values['brandId'],
      'bodyTypeId': values['bodyTypeId'],
      'optionIds': _ids(values, 'optionIds'),
      'horsepower': int.parse(_text(values, 'horsepower')),
      'price': int.parse(_text(values, 'price')),
      'inStock': int.parse(_text(values, 'inStock')),
      'stockTotal': int.parse(_text(values, 'stockTotal')),
    };
    final saved = id == null ? await api.cars.create(body) : await api.cars.update(id, body);
    _cars[saved.id] = saved;
    return saved.id;
  }

  Future<int> _saveBrand(int? id, Map<String, Object?> values) async {
    final body = {
      'name': _text(values, 'name'),
      'country': _text(values, 'country'),
      'foundedYear': int.parse(_text(values, 'foundedYear')),
      'bodyTypeIds': _ids(values, 'bodyTypeIds'),
      'optionIds': _ids(values, 'optionIds'),
    };
    final saved = id == null ? await api.brands.create(body) : await api.brands.update(id, body);
    _brands[saved.id] = saved;
    return saved.id;
  }

  Future<int> _saveBody(int? id, Map<String, Object?> values) async {
    final body = {'name': _text(values, 'name'), 'description': _text(values, 'description')};
    final saved = id == null ? await api.bodies.create(body) : await api.bodies.update(id, body);
    _bodies[saved.id] = saved;
    return saved.id;
  }

  Future<int> _saveOption(int? id, Map<String, Object?> values) async {
    final body = {'name': _text(values, 'name'), 'description': _text(values, 'description')};
    final saved = id == null ? await api.options.create(body) : await api.options.update(id, body);
    _options[saved.id] = saved;
    return saved.id;
  }

  Future<int> _saveClient(int? id, Map<String, Object?> values) async {
    final body = {
      'firstName': _text(values, 'firstName'),
      'lastName': _text(values, 'lastName'),
      'email': _text(values, 'email'),
      'phone': _text(values, 'phone'),
      'license': {
        'number': _text(values, 'licenseNumber'),
        'issuedOn': _text(values, 'issuedOn'),
        'expiresOn': _text(values, 'expiresOn'),
      },
    };
    final saved = id == null ? await api.clients.create(body) : await api.clients.update(id, body);
    _clients[saved.id] = saved;
    return saved.id;
  }

  List<(String, String)> _carDetails(int id) {
    final car = _cars[id];
    if (car == null) {
      return const [];
    }
    return [
      ('Модель', car.model),
      ('VIN', car.vin),
      ('Год', '${car.year}'),
      ('Пробег', '${car.mileage} км'),
      ('Марка', store.brandName(car.brandId)),
      ('Кузов', store.bodyName(car.bodyTypeId)),
      ('Опции', store.optionNames(car.optionIds)),
      ('Мощность', '${car.horsepower} л. с.'),
      ('Цена', '${car.price} ₽'),
      ('На складе', '${car.inStock} из ${car.stockTotal}'),
    ];
  }

  List<(String, String)> _brandDetails(int id) {
    final brand = _brands[id];
    if (brand == null) {
      return const [];
    }
    return [
      ('Название', brand.name),
      ('Страна', brand.country),
      ('Год основания', '${brand.foundedYear}'),
      ('Кузова', store.bodyNameList(brand.bodyTypeIds)),
      ('Опции', store.optionNames(brand.optionIds)),
      ('Автомобилей в каталоге', '${brand.carCount}'),
    ];
  }

  List<(String, String)> _bodyDetails(int id) {
    final body = _bodies[id];
    if (body == null) {
      return const [];
    }
    return [
      ('Название', body.name),
      ('Описание', body.description.isEmpty ? '—' : body.description),
      ('Автомобилей', '${body.carCount}'),
    ];
  }

  List<(String, String)> _optionDetails(int id) {
    final option = _options[id];
    if (option == null) {
      return const [];
    }
    return [
      ('Название', option.name),
      ('Описание', option.description.isEmpty ? '—' : option.description),
      ('Автомобилей', '${option.carCount}'),
    ];
  }

  List<(String, String)> _clientDetails(int id) {
    final client = _clients[id];
    if (client == null) {
      return const [];
    }
    String day(DateTime? value) {
      if (value == null) {
        return '—';
      }
      final month = value.month.toString().padLeft(2, '0');
      final date = value.day.toString().padLeft(2, '0');
      return '${value.year}-$month-$date';
    }

    return [
      ('Имя', client.firstName),
      ('Фамилия', client.lastName),
      ('Почта', client.email),
      ('Телефон', client.phone),
      ('Номер удостоверения', client.license.number),
      ('Выдано', day(client.license.issuedOn)),
      ('Действует до', day(client.license.expiresOn)),
    ];
  }

  String _text(Map<String, Object?> values, String key) {
    final value = values[key];
    return value is String ? value.trim() : '';
  }

  List<int> _ids(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is List<int>) {
      return value;
    }
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return const [];
  }
}

class SessionView {
  const SessionView(this.name, this.roleLabel);

  final String name;
  final String roleLabel;

  bool get signedIn => name.isNotEmpty;
}
