import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../models/entity_kind.dart';
import '../state/catalog_controller.dart';
import '../widgets/confirm.dart';
import '../widgets/extend_form.dart';
import '../widgets/state_views.dart';

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({
    super.key,
    required this.kind,
    required this.id,
    this.preview,
  });

  final EntityKind kind;
  final int id;
  final String? preview;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  var _loading = true;
  String? _error;
  String? _conflict;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = context.read<CatalogController>();
    try {
      await controller.fetch(widget.kind, widget.id);
      if (!mounted) {
        return;
      }
      if (widget.preview == 'delete' && widget.kind == EntityKind.brand) {
        final message = await controller.softDelete(widget.kind, widget.id);
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _conflict = message;
        });
        return;
      }
      if (widget.preview == 'reserve' && widget.kind == EntityKind.car) {
        try {
          await controller.reserve(widget.id);
        } on ConflictException catch (error) {
          _conflict = error.message;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _remove({required bool hard}) async {
    final controller = context.read<CatalogController>();
    final title = controller.titleOf(widget.kind, widget.id) ?? 'запись';
    final ok = await confirmAction(
      context,
      title: hard ? 'Удалить навсегда' : 'Скрыть запись',
      message: hard
          ? '«$title» будет стёрта без восстановления.'
          : '«$title» пропадёт из списка. Запись можно вернуть.',
      confirm: hard ? 'Удалить' : 'Скрыть',
    );
    if (!ok || !mounted) {
      return;
    }
    final message = hard
        ? await controller.hardDelete(widget.kind, widget.id)
        : await controller.softDelete(widget.kind, widget.id);
    if (!mounted) {
      return;
    }
    if (message != null) {
      setState(() => _conflict = message);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.kind.path);
    }
  }

  Future<void> _restore() async {
    await context.read<CatalogController>().restore(widget.kind, widget.id);
    if (mounted) {
      await context.read<CatalogController>().fetch(widget.kind, widget.id);
      setState(() {});
    }
  }

  Future<void> _reserve() async {
    final auth = context.read<AuthNotifier>();
    final dio = context.read<Dio>();
    try {
      List<(int, String)>? people;
      List<(int, String)>? cars;
      if (auth.uiRole == Role.manager && widget.kind == EntityKind.car) {
        people = await _pairs(dio, 'clients', (item) => '${item['lastName']} ${item['firstName']}'.trim());
      }
      if (auth.uiRole == Role.manager && widget.kind == EntityKind.client) {
        cars = await _pairs(dio, 'cars', (item) => '${item['model']}');
      }
      if (!mounted) {
        return;
      }
      final choice = await askBooking(
        context,
        title: 'Продление брони',
        clients: people,
        cars: cars,
        actionLabel: 'Сохранить',
      );
      if (choice == null || !mounted) {
        return;
      }
      final carId = widget.kind == EntityKind.car ? widget.id : choice.carId;
      final response = await dio.post<Object>(
        'cars/$carId/reserve',
        data: {
          'days': choice.days,
          if (widget.kind == EntityKind.client) 'clientId': widget.id,
          if (choice.clientId != null) 'clientId': choice.clientId,
        },
      );
      final data = response.data;
      final reservation = data is Map ? data['reservation'] : null;
      final until = reservation is Map ? reservation['until'] : null;
      final holder = reservation is Map ? reservation['holder'] : null;
      if (!mounted) {
        return;
      }
      await context.read<CatalogController>().fetch(EntityKind.car, carId ?? widget.id);
      if (!mounted) {
        return;
      }
      await showNotice(
        context,
        title: 'Бронь сохранена',
        message: holder == null ? 'Срок обновлён.' : '$holder, дата $until. Форму можно открыть снова и продлить ещё.',
      );
    } on DioException catch (error) {
      final message = error.error is ApiException ? (error.error as ApiException).message : 'Не удалось сохранить бронь';
      if (mounted) {
        await showNotice(context, title: 'Не сохранено', message: message);
      }
    } on ApiException catch (error) {
      if (mounted) {
        await showNotice(context, title: 'Не сохранено', message: error.message);
      }
    }
  }

  Future<List<(int, String)>> _pairs(
    Dio dio,
    String path,
    String Function(Map<String, dynamic>) label,
  ) async {
    final sort = path == 'clients' ? 'lastName,asc' : 'model,asc';
    final response = await dio.get<Object>(path, queryParameters: {'page': '1', 'size': '100', 'sort': sort});
    final data = response.data;
    final items = data is Map && data['items'] is List ? data['items'] as List : const [];
    return [
      for (final item in items)
        if (item is Map)
          (
            item['id'] is int ? item['id'] as int : int.tryParse('${item['id']}') ?? 0,
            label(item.map((key, value) => MapEntry('$key', value))),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CatalogController>();
    final rows = controller.details(widget.kind, widget.id);
    final title = controller.titleOf(widget.kind, widget.id);
    final deleted = controller.isDeleted(widget.kind, widget.id);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.kind.path);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title ?? 'Запись'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const LoadingView(label: 'Загрузка записи…')
          else if (_error != null)
            ErrorView(message: _error!, onRetry: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _open();
            })
          else if (title == null)
            const Center(child: Text('Запись не найдена.'))
          else
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    if (deleted)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Запись скрыта'),
                      ),
                    const SizedBox(height: 16),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 220, child: Text(row.$1)),
                            Expanded(child: Text(row.$2)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (context.watch<AuthNotifier>().allowsAction(
                          widget.kind == EntityKind.client ? SalonAction.manageClients : SalonAction.editCatalog,
                        )) ...[
                        FilledButton.icon(
                          onPressed: () => context.push('${widget.kind.path}/${widget.id}/edit'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Изменить'),
                        ),
                        if (widget.kind == EntityKind.car && context.watch<AuthNotifier>().uiRole == Role.manager)
                          FilledButton.tonalIcon(
                            onPressed: _reserve,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Зарезервировать'),
                          ),
                        if (deleted && context.watch<AuthNotifier>().allowsAction(SalonAction.restoreRecords))
                          OutlinedButton.icon(
                            onPressed: _restore,
                            icon: const Icon(Icons.restore),
                            label: const Text('Вернуть в каталог'),
                          )
                        else if (!deleted)
                          FilledButton.tonalIcon(
                            onPressed: () => _remove(hard: false),
                            icon: const Icon(Icons.delete),
                            label: const Text('Скрыть'),
                          ),
                        ],
                        if (widget.kind == EntityKind.car &&
                            !deleted &&
                            context.watch<AuthNotifier>().uiRole == Role.reader)
                          FilledButton.tonalIcon(
                            onPressed: _reserve,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Зарезервировать'),
                          ),
                        if (widget.kind == EntityKind.client &&
                            !deleted &&
                            context.watch<AuthNotifier>().uiRole == Role.manager)
                          FilledButton.tonalIcon(
                            onPressed: _reserve,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Забронировать'),
                          ),
                        if (context.watch<AuthNotifier>().allowsAction(SalonAction.hardDelete))
                          OutlinedButton.icon(
                            onPressed: () => _remove(hard: true),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Удалить навсегда'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_conflict != null)
            NoticePanel(
              title: 'Операция невозможна',
              message: _conflict!,
            ),
        ],
      ),
    );
  }
}
