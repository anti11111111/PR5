import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../models/body_type.dart';
import '../models/brand.dart';
import '../models/car.dart';
import '../models/client.dart';
import '../models/entity_kind.dart';
import '../models/list_query.dart';
import '../models/option.dart';
import '../core/api_exceptions.dart';
import '../state/catalog_controller.dart';
import '../state/load_status.dart';
import '../widgets/confirm.dart';
import '../widgets/state_views.dart';
import '../widgets/entity_cards.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class CatalogListScreen extends StatefulWidget {
  const CatalogListScreen({super.key, required this.kind});

  final EntityKind kind;

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  final _search = TextEditingController();
  final _yearFrom = TextEditingController();
  final _yearTo = TextEditingController();
  Timer? _searchDebounce;
  Timer? _yearDebounce;
  ListQuery? _applied;
  var _syncing = false;
  var _asked = false;
  String? _denied;

  EntityKind get kind => widget.kind;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (!_asked && uri.queryParameters['act'] == 'hard') {
      _asked = true;
      _forceDeny();
    }
    final next = ListQuery.fromUri(
      uri,
      allowedSort: kind.allowedSort,
      defaultSort: kind.defaultSort,
    );
    _syncFields(next);
    if (_applied == next) {
      context.read<CatalogController>().replaceSelection(kind, _selectedIds(uri));
      return;
    }
    _applied = next;
    final controller = context.read<CatalogController>();
    controller.apply(kind, next);
    controller.replaceSelection(kind, _selectedIds(uri));
  }

  Set<int> _selectedIds(Uri uri) {
    final raw = uri.queryParameters['selected'];
    if (raw == null || raw.isEmpty) {
      return {};
    }
    return raw.split(',').map(int.tryParse).whereType<int>().toSet();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _yearDebounce?.cancel();
    _search.dispose();
    _yearFrom.dispose();
    _yearTo.dispose();
    super.dispose();
  }

  void _syncFields(ListQuery query) {
    _syncing = true;
    if (!(_searchDebounce?.isActive ?? false) && _search.text != query.search) {
      _search.text = query.search;
    }
    if (kind == EntityKind.car && !(_yearDebounce?.isActive ?? false)) {
      final from = query.yearFrom?.toString() ?? '';
      final to = query.yearTo?.toString() ?? '';
      if (_yearFrom.text != from) {
        _yearFrom.text = from;
      }
      if (_yearTo.text != to) {
        _yearTo.text = to;
      }
    }
    _syncing = false;
  }

  String _visibleAddress(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters)
      ..remove('demoError')
      ..remove('previewLoading')
      ..remove('preview');
    if (params.isEmpty) {
      return uri.path;
    }
    return Uri(path: uri.path, queryParameters: params).toString();
  }

  void _go(ListQuery query, {Set<int>? selected}) {
    final params = query.toParams();
    final ids = selected ?? context.read<CatalogController>().slice(kind).selected;
    if (selected == null) {
      // Фильтр, сортировка и страница начинают выбор заново.
      params.remove('selected');
    } else if (ids.isNotEmpty) {
      final sorted = ids.toList()..sort();
      params['selected'] = sorted.join(',');
    }
    context.go(Uri(path: kind.path, queryParameters: params).toString());
  }

  void _onSearch(String value) {
    if (_syncing) {
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      _go(context.read<CatalogController>().slice(kind).query.copyWith(search: value), selected: {});
    });
  }

  void _onYear(String _) {
    if (_syncing) {
      return;
    }
    _yearDebounce?.cancel();
    _yearDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      final fromText = _yearFrom.text.trim();
      final toText = _yearTo.text.trim();
      if (fromText.isNotEmpty && int.tryParse(fromText) == null) {
        return;
      }
      if (toText.isNotEmpty && int.tryParse(toText) == null) {
        return;
      }
      _go(
        context.read<CatalogController>().slice(kind).query.copyWith(
          yearFrom: fromText.isEmpty ? null : int.parse(fromText),
          yearTo: toText.isEmpty ? null : int.parse(toText),
        ),
        selected: {},
      );
    });
  }

  Future<void> _forceDeny() async {
    final message = await context.read<CatalogController>().hardDelete(kind, 1);
    if (!mounted) {
      return;
    }
    setState(() => _denied = message ?? 'Недостаточно прав для этого действия.');
  }

  Future<void> _soft(int id, String title) async {
    final ok = await confirmAction(
      context,
      title: 'Скрыть запись',
      message: '«$title» пропадёт из списка. Запись можно вернуть.',
      confirm: 'Скрыть',
    );
    if (!ok || !mounted) {
      return;
    }
    final message = await context.read<CatalogController>().softDelete(kind, id);
    if (message != null && mounted) {
      await showNotice(context, title: 'Удаление невозможно', message: message);
    }
  }

  Future<void> _hard(int id, String title) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: '«$title» будет стёрта без восстановления.',
    );
    if (!ok || !mounted) {
      return;
    }
    final message = await context.read<CatalogController>().hardDelete(kind, id);
    if (message != null && mounted) {
      await showNotice(context, title: 'Удаление невозможно', message: message);
    }
  }

  Future<void> _deleteSelected() async {
    final controller = context.read<CatalogController>();
    final ok = await confirmAction(
      context,
      title: 'Удалить выбранные',
      message: 'Скрыть записей: ${controller.slice(kind).selected.length}.',
      confirm: 'Скрыть',
    );
    if (!ok || !mounted) {
      return;
    }
    final removed = await context.read<CatalogController>().deleteSelected(kind);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скрыто записей: $removed')));
  }

  void _toggle(int id) {
    final selected = {...context.read<CatalogController>().slice(kind).selected};
    if (!selected.add(id)) {
      selected.remove(id);
    }
    _go(context.read<CatalogController>().slice(kind).query, selected: selected);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CatalogController>();
    final slice = controller.slice(kind);
    final query = slice.query;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final auth = context.watch<AuthNotifier>();
    final canEdit = auth.allowsAction(
      kind == EntityKind.client ? SalonAction.manageClients : SalonAction.editCatalog,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(kind.title),
        actions: [
          if (!narrow && auth.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: Text('${auth.user!.name} · ${roleLabel(auth.uiRole)}')),
            ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<CatalogController>().reload(kind),
            icon: const Icon(Icons.refresh),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Добавить',
              onPressed: () => context.push('${kind.path}/new'),
              icon: const Icon(Icons.add),
            ),
          PopupMenuButton<EntityKind>(
            tooltip: 'Разделы',
            icon: const Icon(Icons.menu),
            onSelected: (value) => context.go(value.path),
            itemBuilder: (context) => [
              for (final item in EntityKind.values)
                if (item != EntityKind.client || auth.uiRole == Role.manager)
                  PopupMenuItem(value: item, child: Text(item.title)),
            ],
          ),
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          labelText: kind.searchLabel,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _onSearch,
                      ),
                    ),
                    ..._filters(controller, query),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: query.includeDeleted,
                          onChanged: (value) =>
                              _go(query.copyWith(includeDeleted: value), selected: {}),
                        ),
                        const Text('Показывать скрытые'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _visibleAddress(GoRouterState.of(context).uri),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
          if (slice.selected.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('Выбрано: ${slice.selected.length}'),
                    const Spacer(),
                    if (canEdit)
                      TextButton(onPressed: _deleteSelected, child: const Text('Удалить выбранные')),
                  ],
                ),
              ),
            ),
          Expanded(child: _body(context, controller, narrow)),
          PaginationBar(
            page: slice.result.page,
            totalPages: slice.result.totalPages,
            total: slice.result.total,
            size: query.size,
            onPage: (page) => _go(query.copyWith(page: page), selected: {}),
            onSize: (size) => _go(query.copyWith(size: size), selected: {}),
          ),
        ],
      ),
          if (_denied != null)
            NoticePanel(title: 'Операция невозможна', message: _denied!),
        ],
      ),
    );
  }

  List<Widget> _filters(CatalogController controller, ListQuery query) {
    return switch (kind) {
      EntityKind.car => [
        _dropdown<int?>(
          label: 'Марка',
          value: query.brandId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Все марки')),
            for (final brand in controller.store.liveBrands())
              DropdownMenuItem(value: brand.id, child: Text(brand.name)),
          ],
          onChanged: (value) => _go(query.copyWith(brandId: value), selected: {}),
        ),
        _dropdown<int?>(
          label: 'Кузов',
          value: query.bodyTypeId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Все кузова')),
            for (final body in controller.store.liveBodyTypes())
              DropdownMenuItem(value: body.id, child: Text(body.name)),
          ],
          onChanged: (value) => _go(query.copyWith(bodyTypeId: value), selected: {}),
        ),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _yearFrom,
            decoration: const InputDecoration(
              labelText: 'Год от',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: _onYear,
          ),
        ),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _yearTo,
            decoration: const InputDecoration(
              labelText: 'Год до',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: _onYear,
          ),
        ),
      ],
      EntityKind.brand => [
        _dropdown<String?>(
          label: 'Страна',
          value: query.country,
          items: [
            const DropdownMenuItem(value: null, child: Text('Все страны')),
            for (final country in controller.store.brandCountries())
              DropdownMenuItem(value: country, child: Text(country)),
          ],
          onChanged: (value) => _go(query.copyWith(country: value), selected: {}),
        ),
      ],
      EntityKind.bodyType || EntityKind.option || EntityKind.client => const [],
    };
  }

  Widget _body(BuildContext context, CatalogController controller, bool narrow) {
    final slice = controller.slice(kind);
    switch (slice.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        if (slice.failure is ForbiddenException) {
          return ForbiddenView(message: slice.error ?? 'Недостаточно прав для этого действия.');
        }
        return ErrorView(
          message: slice.error ?? 'Ошибка загрузки',
          onRetry: () => context.read<CatalogController>().reload(kind),
        );
      case LoadStatus.success:
        if (slice.result.total == 0) {
          return const EmptyView();
        }
        if (slice.result.items.isEmpty) {
          return const Center(child: Text('На этой странице нет записей'));
        }
        return switch (kind) {
          EntityKind.car => _view<Car>(
            controller,
            narrow,
            controller.cars.result.items,
            (car) => car.id,
            (car) => car.isDeleted,
            (car) => car.model,
            [
              _titleColumn<Car>('Модель', 'model', (car) => car.model, (car) => car.isDeleted),
              TableColumnSpec(label: 'VIN', build: (car) => Text(car.vin)),
              TableColumnSpec(
                label: 'Год',
                sortField: 'year',
                numeric: true,
                build: (car) => Text('${car.year}'),
              ),
              TableColumnSpec(
                label: 'Пробег',
                sortField: 'mileage',
                numeric: true,
                build: (car) => Text('${car.mileage}'),
              ),
              TableColumnSpec(
                label: 'Марка',
                build: (car) => Text(controller.store.brandName(car.brandId)),
              ),
            ],
            (car) => car.model,
            (car) => '${car.year} · ${controller.store.brandName(car.brandId)}\n${car.vin}',
          ),
          EntityKind.brand => _view<Brand>(
            controller,
            narrow,
            controller.brands.result.items,
            (item) => item.id,
            (item) => item.isDeleted,
            (item) => item.name,
            [
              _titleColumn<Brand>('Название', 'name', (item) => item.name, (item) => item.isDeleted),
              TableColumnSpec(
                label: 'Страна',
                sortField: 'country',
                build: (item) => Text(item.country),
              ),
              TableColumnSpec(
                label: 'Год основания',
                sortField: 'foundedYear',
                numeric: true,
                build: (item) => Text('${item.foundedYear}'),
              ),
            ],
            (item) => item.name,
            (item) => '${item.country}, ${item.foundedYear}',
          ),
          EntityKind.bodyType => _view<BodyType>(
            controller,
            narrow,
            controller.bodyTypes.result.items,
            (item) => item.id,
            (item) => item.isDeleted,
            (item) => item.name,
            [
              _titleColumn<BodyType>('Название', 'name', (item) => item.name, (item) => item.isDeleted),
              TableColumnSpec(
                label: 'Описание',
                sortField: 'description',
                build: (item) => Text(item.description),
              ),
              TableColumnSpec(
                label: 'Машин',
                sortField: 'cars',
                numeric: true,
                build: (item) => Text('${item.carCount}'),
              ),
            ],
            (item) => item.name,
            (item) => item.description,
          ),
          EntityKind.option => _view<Option>(
            controller,
            narrow,
            controller.options.result.items,
            (item) => item.id,
            (item) => item.isDeleted,
            (item) => item.name,
            [
              _titleColumn<Option>('Название', 'name', (item) => item.name, (item) => item.isDeleted),
              TableColumnSpec(
                label: 'Описание',
                sortField: 'description',
                build: (item) => Text(item.description),
              ),
              TableColumnSpec(
                label: 'Машин',
                sortField: 'cars',
                numeric: true,
                build: (item) => Text('${item.carCount}'),
              ),
            ],
            (item) => item.name,
            (item) => item.description,
          ),
          EntityKind.client => _view<Client>(
            controller,
            narrow,
            controller.clients.result.items,
            (item) => item.id,
            (item) => item.isDeleted,
            (item) => item.fullName,
            [
              _titleColumn<Client>(
                'Фамилия',
                'lastName',
                (item) => item.lastName,
                (item) => item.isDeleted,
              ),
              TableColumnSpec(
                label: 'Почта',
                sortField: 'email',
                build: (item) => Text(item.email),
              ),
              TableColumnSpec(
                label: 'Права',
                sortField: 'licenseNumber',
                build: (item) => Text(item.license.number),
              ),
            ],
            (item) => item.fullName,
            (item) => '${item.email}\n${item.license.number}',
          ),
        };
    }
  }

  TableColumnSpec<T> _titleColumn<T extends Object>(
    String label,
    String sortField,
    String Function(T item) text,
    bool Function(T item) deleted,
  ) {
    return TableColumnSpec(
      label: label,
      sortField: sortField,
      build: (item) => InkWell(
        onTap: () => context.push('$kind.path/${_idOf(item)}'),
        child: Text(
          text(item),
          style: TextStyle(decoration: deleted(item) ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }

  int _idOf(Object item) {
    return switch (item) {
      Car car => car.id,
      Brand brand => brand.id,
      BodyType body => body.id,
      Option option => option.id,
      Client client => client.id,
      _ => 0,
    };
  }

  Widget _view<T>(
    CatalogController controller,
    bool narrow,
    List<T> items,
    int Function(T item) idOf,
    bool Function(T item) deleted,
    String Function(T item) name,
    List<TableColumnSpec<T>> columns,
    String Function(T item) cardTitle,
    String Function(T item) cardSubtitle,
  ) {
    final selected = controller.slice(kind).selected;
    if (narrow) {
      return EntityCards<T>(
        items: items,
        idOf: idOf,
        selected: selected,
        onToggleSelect: _toggle,
        isDeleted: deleted,
        onOpen: (item) => context.push('${kind.path}/${idOf(item)}'),
        title: (item) => Text(
          cardTitle(item),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: deleted(item) ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: (item) => Text(cardSubtitle(item)),
        actions: (item) => _actions(idOf(item), name(item), deleted(item)),
      );
    }
    return EntityTable<T>(
      items: items,
      idOf: idOf,
      selected: selected,
      onToggleSelect: _toggle,
      sortField: controller.slice(kind).query.sortField,
      sortAscending: controller.slice(kind).query.sortAscending,
      onSort: (field) {
        final query = controller.slice(kind).query;
        final same = field == query.sortField;
        _go(
          query.copyWith(sortField: field, sortAscending: same ? !query.sortAscending : true),
          selected: {},
        );
      },
      isDeleted: deleted,
      columns: columns,
      actions: (item) => _actions(idOf(item), name(item), deleted(item)),
    );
  }

  List<Widget> _actions(int id, String title, bool deleted) {
    final auth = context.watch<AuthNotifier>();
    final canEdit = auth.allowsAction(
      kind == EntityKind.client ? SalonAction.manageClients : SalonAction.editCatalog,
    );
    if (deleted) {
      return [
        if (auth.allowsAction(SalonAction.restoreRecords))
          IconButton(
            tooltip: 'Вернуть в каталог',
            icon: const Icon(Icons.restore),
            onPressed: () => context.read<CatalogController>().restore(kind, id),
          ),
        if (auth.allowsAction(SalonAction.hardDelete))
          IconButton(
            tooltip: 'Удалить навсегда',
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _hard(id, title),
          ),
      ];
    }
    if (!canEdit) {
      return const [];
    }
    return [
      IconButton(
        tooltip: 'Скрыть',
        icon: const Icon(Icons.delete),
        onPressed: () => _soft(id, title),
      ),
    ];
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<T>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
