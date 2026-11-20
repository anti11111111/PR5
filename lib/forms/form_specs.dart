import '../data/catalog_cache.dart';
import '../models/entity_kind.dart';
import '../validation/validators.dart';
import 'field_spec.dart';

String _s(Object? value) => value is String ? value : '';

int? _choice(Object? value) => value is int ? value : null;

List<int> _idList(Object? value) {
  if (value is List<int>) {
    return value;
  }
  if (value is List) {
    return value.whereType<int>().toList();
  }
  return const [];
}

List<FieldSpec> specsFor(EntityKind kind, CatalogCache store) {
  return switch (kind) {
    EntityKind.car => _car(store),
    EntityKind.brand => _brand(store),
    EntityKind.bodyType => _named(),
    EntityKind.option => _named(),
    EntityKind.client => _client(store),
  };
}

List<FieldSpec> _car(CatalogCache store) => [
  FieldSpec(
    key: 'model',
    label: 'Модель',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['model']), label: 'Модель', max: 80),
  ),
  FieldSpec(
    key: 'vin',
    label: 'VIN',
    kind: FieldKind.text,
    validate: (values) {
      return vinFormat(_s(values['vin']));
    },
  ),
  FieldSpec(
    key: 'year',
    label: 'Год выпуска',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['year']), label: 'Год выпуска', min: 1950, max: 2026),
  ),
  FieldSpec(
    key: 'mileage',
    label: 'Пробег, км',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['mileage']), label: 'Пробег', min: 0, max: 2000000),
  ),
  FieldSpec(
    key: 'brandId',
    label: 'Марка',
    kind: FieldKind.dropdown,
    options: (_) => [
      for (final brand in store.liveBrands()) LookupOption(brand.id, brand.name),
    ],
    validate: (values) => requiredChoice(_choice(values['brandId']), 'Выберите марку'),
  ),
  FieldSpec(
    key: 'bodyTypeId',
    label: 'Кузов',
    kind: FieldKind.dropdown,
    options: (values) => [
      for (final body in store.bodiesForBrand(_choice(values['brandId'])))
        LookupOption(body.id, body.name),
    ],
    validate: (values) {
      final id = _choice(values['bodyTypeId']);
      final missing = requiredChoice(id, 'Выберите кузов');
      if (missing != null) {
        return missing;
      }
      final offered = store.bodiesForBrand(_choice(values['brandId']));
      if (!offered.any((item) => item.id == id)) {
        return 'Эта марка такой кузов не предлагает';
      }
      return null;
    },
  ),
  FieldSpec(
    key: 'optionIds',
    label: 'Опции',
    kind: FieldKind.chips,
    options: (values) => [
      for (final option in store.optionsForBrand(_choice(values['brandId'])))
        LookupOption(option.id, option.name),
    ],
    validate: (values) {
      final ids = _idList(values['optionIds']);
      final missing = requiredIds(ids, 'Выберите хотя бы одну опцию');
      if (missing != null) {
        return missing;
      }
      final offered = store.optionsForBrand(_choice(values['brandId'])).map((item) => item.id).toSet();
      if (ids.any((id) => !offered.contains(id))) {
        return 'Есть опция, которую марка не предлагает';
      }
      return null;
    },
  ),
  FieldSpec(
    key: 'horsepower',
    label: 'Мощность, л. с.',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['horsepower']), label: 'Мощность', min: 40, max: 1500),
  ),
  FieldSpec(
    key: 'price',
    label: 'Цена, ₽',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['price']), label: 'Цена', min: 1, max: 50000000),
  ),
  FieldSpec(
    key: 'stockTotal',
    label: 'Всего на складе',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['stockTotal']), label: 'Всего на складе', min: 1, max: 100),
  ),
  FieldSpec(
    key: 'inStock',
    label: 'Свободно',
    kind: FieldKind.number,
    validate: (values) {
      final total = int.tryParse(_s(values['stockTotal'])) ?? 0;
      return intInRange(
        _s(values['inStock']),
        label: 'Свободно',
        min: 0,
        max: total < 0 ? 0 : total,
      );
    },
  ),
];

List<FieldSpec> _brand(CatalogCache store) => [
  FieldSpec(
    key: 'name',
    label: 'Название',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['name']), label: 'Название', max: 80),
  ),
  FieldSpec(
    key: 'country',
    label: 'Страна',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['country']), label: 'Страна', max: 60),
  ),
  FieldSpec(
    key: 'foundedYear',
    label: 'Год основания',
    kind: FieldKind.number,
    validate: (values) => intInRange(_s(values['foundedYear']), label: 'Год основания', min: 1800, max: 2026),
  ),
  FieldSpec(
    key: 'bodyTypeIds',
    label: 'Какие кузова продаёт',
    kind: FieldKind.chips,
    options: (_) => [
      for (final body in store.liveBodyTypes()) LookupOption(body.id, body.name),
    ],
    validate: (values) => requiredIds(_idList(values['bodyTypeIds']), 'Выберите хотя бы один кузов'),
  ),
  FieldSpec(
    key: 'optionIds',
    label: 'Какие опции ставит',
    kind: FieldKind.chips,
    options: (_) => [
      for (final option in store.liveOptions()) LookupOption(option.id, option.name),
    ],
    validate: (values) => requiredIds(_idList(values['optionIds']), 'Выберите хотя бы одну опцию'),
  ),
];

List<FieldSpec> _named() => [
  FieldSpec(
    key: 'name',
    label: 'Название',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['name']), label: 'Название', max: 80),
  ),
  FieldSpec(
    key: 'description',
    label: 'Описание',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['description']), label: 'Описание', min: 3, max: 200),
  ),
];

List<FieldSpec> _client(CatalogCache store) => [
  FieldSpec(
    key: 'firstName',
    label: 'Имя',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['firstName']), label: 'Имя', max: 40),
  ),
  FieldSpec(
    key: 'lastName',
    label: 'Фамилия',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['lastName']), label: 'Фамилия', max: 40),
  ),
  FieldSpec(
    key: 'email',
    label: 'Почта',
    kind: FieldKind.email,
    validate: (values) {
      return emailFormat(_s(values['email']));
    },
  ),
  FieldSpec(
    key: 'phone',
    label: 'Телефон',
    kind: FieldKind.text,
    validate: (values) => phoneFormat(_s(values['phone'])),
  ),
  const FieldSpec(key: 'license', label: 'Водительское удостоверение', kind: FieldKind.section),
  FieldSpec(
    key: 'licenseNumber',
    label: 'Номер удостоверения',
    kind: FieldKind.text,
    validate: (values) => requiredText(_s(values['licenseNumber']), label: 'Номер удостоверения', min: 6, max: 20),
  ),
  FieldSpec(
    key: 'issuedOn',
    label: 'Дата выдачи',
    kind: FieldKind.date,
    validate: (values) => dateText(_s(values['issuedOn']), label: 'дату выдачи'),
  ),
  FieldSpec(
    key: 'expiresOn',
    label: 'Действует до',
    kind: FieldKind.date,
    validate: (values) {
      final format = dateText(_s(values['expiresOn']), label: 'дату окончания');
      if (format != null) {
        return format;
      }
      final issued = DateTime.tryParse(_s(values['issuedOn']));
      final expires = DateTime.tryParse(_s(values['expiresOn']));
      if (issued != null && expires != null && !expires.isAfter(issued)) {
        return 'Срок должен быть позже даты выдачи';
      }
      return null;
    },
  ),
];
