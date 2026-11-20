import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../widgets/confirm.dart';
import '../widgets/extend_form.dart';

String _message(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  return 'Не удалось выполнить запрос';
}

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = context.read<Dio>();
      final response = await dio.get<Object>('my-reservations');
      final data = response.data;
      final items = data is Map && data['items'] is List ? data['items'] as List : const [];
      setState(() {
        _items = [for (final item in items) if (item is Map) item.map((key, value) => MapEntry('$key', value))];
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  Future<void> _extend(Map<String, dynamic> item) async {
    final choice = await askBooking(
      context,
      title: 'Продление брони',
      until: '${item['until']}',
    );
    if (choice == null || !mounted) {
      return;
    }
    try {
      final response = await context.read<Dio>().post<Object>(
        'my-reservations/${item['id']}/extend',
        data: {'days': choice.days},
      );
      final data = response.data;
      final until = data is Map ? data['until'] : null;
      if (mounted) {
        await showNotice(context, title: 'Бронь продлена', message: 'Новая дата: $until');
      }
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои брони'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: Text('Загрузка…'))
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Брони текущего читателя. «Продлить» открывает форму: дни прибавляются к дате, поэтому бронь можно продлевать снова.',
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const Text('Открытых броней нет. Откройте автомобиль и нажмите «Зарезервировать».'),
                for (final item in _items)
                  ListTile(
                    title: Text('${item['model']}'),
                    subtitle: Text('До ${item['until']}'),
                    trailing: FilledButton(
                      onPressed: () => _extend(item),
                      child: const Text('Продлить'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class DeskScreen extends StatefulWidget {
  const DeskScreen({super.key});

  @override
  State<DeskScreen> createState() => _DeskScreenState();
}

class _DeskScreenState extends State<DeskScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await context.read<Dio>().get<Object>('desk/reservations');
      final data = response.data;
      final items = data is Map && data['items'] is List ? data['items'] as List : const [];
      setState(() {
        _items = [for (final item in items) if (item is Map) item.map((key, value) => MapEntry('$key', value))];
      });
    } catch (error) {
      setState(() => _error = _message(error));
    }
  }

  Future<void> _extend(Map<String, dynamic> item) async {
    final choice = await askBooking(
      context,
      title: 'Продление брони',
      until: '${item['until']}',
    );
    if (choice == null || !mounted) {
      return;
    }
    try {
      final response = await context.read<Dio>().post<Object>(
        'desk/reservations/${item['id']}/extend',
        data: {'days': choice.days},
      );
      final data = response.data;
      final until = data is Map ? data['until'] : null;
      if (mounted) {
        await showNotice(context, title: 'Бронь продлена', message: '${item['holder']}: новая дата $until');
      }
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error));
      }
    }
  }

  Future<void> _close(int id) async {
    try {
      await context.read<Dio>().post<Object>('desk/reservations/$id/close');
      await _load();
    } catch (error) {
      setState(() => _error = _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Стойка менеджера'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Здесь брони Анны и всех клиентов. «Продлить» открывает форму и сдвигает дату дальше, «Закрыть» завершает бронь.',
          ),
          if (_error != null) Text(_error!),
          for (final item in _items)
            ListTile(
              title: Text('${item['model']} · ${item['holder']}'),
              subtitle: Text('${item['status']} до ${item['until']}'),
              trailing: item['status'] == 'open'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => _extend(item),
                          child: const Text('Продлить'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _close(item['id'] is int ? item['id'] as int : 0),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await context.read<Dio>().get<Object>('users');
      final data = response.data;
      final items = data is Map && data['items'] is List ? data['items'] as List : const [];
      setState(() {
        _items = [for (final item in items) if (item is Map) item.map((key, value) => MapEntry('$key', value))];
      });
    } catch (error) {
      setState(() => _error = _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Экран только для администратора: список учётных записей и их роли.'),
          if (_error != null) Text(_error!),
          for (final item in _items)
            ListTile(title: Text('${item['name']}'), subtitle: Text('${item['email']} · ${item['role']}')),
        ],
      ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await context.read<Dio>().get<Object>('stats');
      final data = response.data;
      setState(() {
        _stats = data is Map ? data.map((key, value) => MapEntry('$key', value)) : {};
      });
    } catch (error) {
      setState(() => _error = _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _error != null
            ? Text(_error!)
            : stats == null
            ? const Text('Загрузка…')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сводка салона видна только администратору.'),
                  const SizedBox(height: 12),
                  Text('Автомобили: ${stats['cars']}'),
                  Text('Марки: ${stats['brands']}'),
                  Text('Клиенты: ${stats['clients']}'),
                  Text('Пользователи: ${stats['users']}'),
                  Text('Открытые брони: ${stats['reservations']}'),
                ],
              ),
      ),
    );
  }
}
