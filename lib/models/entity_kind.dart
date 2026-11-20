enum EntityKind { car, brand, bodyType, option, client }

extension EntityKindData on EntityKind {
  String get path => switch (this) {
    EntityKind.car => '/cars',
    EntityKind.brand => '/brands',
    EntityKind.bodyType => '/bodies',
    EntityKind.option => '/options',
    EntityKind.client => '/clients',
  };

  String get title => switch (this) {
    EntityKind.car => 'Автомобили',
    EntityKind.brand => 'Марки',
    EntityKind.bodyType => 'Кузова',
    EntityKind.option => 'Опции',
    EntityKind.client => 'Клиенты',
  };

  String get searchLabel => switch (this) {
    EntityKind.car => 'Поиск по модели и VIN',
    EntityKind.brand => 'Поиск по названию и стране',
    EntityKind.bodyType => 'Поиск по названию и описанию',
    EntityKind.option => 'Поиск по названию и описанию',
    EntityKind.client => 'Поиск по фамилии и почте',
  };

  String get defaultSort => switch (this) {
    EntityKind.car => 'model',
    EntityKind.brand => 'name',
    EntityKind.bodyType => 'name',
    EntityKind.option => 'name',
    EntityKind.client => 'lastName',
  };

  Set<String> get allowedSort => switch (this) {
    EntityKind.car => {'model', 'year', 'mileage'},
    EntityKind.brand => {'name', 'country', 'foundedYear'},
    EntityKind.bodyType => {'name', 'description', 'cars'},
    EntityKind.option => {'name', 'description', 'cars'},
    EntityKind.client => {'lastName', 'email', 'licenseNumber'},
  };

  String formTitle(bool editing) => switch (this) {
    EntityKind.car => editing ? 'Изменение автомобиля' : 'Новый автомобиль',
    EntityKind.brand => editing ? 'Изменение марки' : 'Новая марка',
    EntityKind.bodyType => editing ? 'Изменение кузова' : 'Новый кузов',
    EntityKind.option => editing ? 'Изменение опции' : 'Новая опция',
    EntityKind.client => editing ? 'Изменение клиента' : 'Новый клиент',
  };
}
