import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../forms/field_spec.dart';
import '../forms/form_specs.dart';
import '../forms/spec_form.dart';
import '../models/entity_kind.dart';
import '../state/catalog_controller.dart';
import '../widgets/confirm.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({
    super.key,
    required this.kind,
    this.id,
    this.preview,
  });

  final EntityKind kind;
  final int? id;
  final String? preview;

  bool get isEditing => id != null;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<SpecFormState>();
  Map<String, Object?>? _initial;
  final _serverErrors = <String, String>{};
  var _dirty = false;
  var _leaving = false;
  String? _missing;

  @override
  void initState() {
    super.initState();
    final controller = context.read<CatalogController>();
    if (widget.id == null) {
      final specs = specsFor(widget.kind, controller.store);
      final values = _withPreview(emptyForm(specs));
      if (widget.preview == 'duplicate') {
        _prepareDuplicate(values);
      } else {
        _initial = values;
        _schedulePreview();
      }
    } else {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final controller = context.read<CatalogController>();
    try {
      await controller.fetch(widget.kind, widget.id!);
      if (!mounted) {
        return;
      }
      final loaded = controller.formOf(widget.kind, widget.id!);
      setState(() {
        if (loaded == null) {
          _missing = 'Запись не найдена.';
        } else {
          _initial = loaded;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _missing = error.message);
    }
  }

  Map<String, Object?> _withPreview(Map<String, Object?> values) {
    switch (widget.preview) {
      case 'duplicate':
        return {
          ...values,
          'model': 'Повтор',
          'vin': 'XTA000001',
          'year': '2020',
          'mileage': '10000',
          'brandId': 1,
          'bodyTypeId': 1,
          'optionIds': <int>[1],
          'horsepower': '150',
          'price': '1500000',
          'stockTotal': '2',
          'inStock': '1',
        };
      case 'cascade':
        return {...values, 'brandId': 1};
      case 'leave':
        return {...values, 'model': 'Черновик'};
      case 'save':
        return {
          ...values,
          'model': 'Проверочная',
          'vin': 'XTA000777',
          'year': '2024',
          'mileage': '1500',
          'brandId': 1,
          'bodyTypeId': 1,
          'optionIds': <int>[1],
          'horsepower': '150',
          'price': '1500000',
          'stockTotal': '2',
          'inStock': '2',
        };
      default:
        return values;
    }
  }

  void _schedulePreview() {
    final preview = widget.preview;
    if (preview == null || preview == 'cascade') {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (preview == 'invalid') {
        _formKey.currentState?.validate();
      } else if (preview == 'leave') {
        await _askLeave();
      } else if (preview == 'save') {
        await _formKey.currentState?.submit();
      }
    });
  }

  /// Запрос уходит до первого кадра, чтобы ответ 422 был виден сразу.
  Future<void> _prepareDuplicate(Map<String, Object?> values) async {
    try {
      await context.read<CatalogController>().saveForm(widget.kind, null, values);
    } on ValidationException catch (error) {
      _serverErrors.addAll(error.errors);
    } on ApiException {
      // Форма всё равно откроется: текст ошибки придёт при обычной отправке.
    }
    if (!mounted) {
      return;
    }
    setState(() => _initial = values);
  }

  Future<void> _submit(Map<String, Object?> values) async {
    try {
      final id = await context.read<CatalogController>().saveForm(widget.kind, widget.id, values);
      if (!mounted) {
        return;
      }
      _dirty = false;
      _leaving = true;
      if (widget.preview == 'save') {
        context.go('${widget.kind.path}?search=Проверочная');
        return;
      }
      context.go('${widget.kind.path}/$id');
    } on ValidationException catch (error) {
      _formKey.currentState?.applyServerErrors(error.errors);
    } on ApiException catch (error) {
      if (mounted) {
        await showNotice(context, title: 'Не сохранено', message: error.message);
      }
    }
  }

  Future<bool> _askLeave() {
    return confirmAction(
      context,
      title: 'Есть несохранённые изменения',
      message: 'Уйти со страницы без сохранения?',
      confirm: 'Уйти',
    );
  }

  Future<void> _tryLeave() async {
    if (!_dirty) {
      _leave();
      return;
    }
    final ok = await _askLeave();
    if (ok && mounted) {
      _dirty = false;
      _leave();
    }
  }

  void _leave() {
    _leaving = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.kind.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;
    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _leaving) {
          return;
        }
        final ok = await _askLeave();
        if (ok && mounted) {
          _dirty = false;
          _leave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Назад',
            onPressed: _tryLeave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(widget.kind.formTitle(editing)),
        ),
        body: Stack(
          children: [
            _body(editing),
            if (widget.preview == 'leave')
              const NoticePanel(
                title: 'Есть несохранённые изменения',
                message: 'Уйти со страницы без сохранения?',
                confirm: 'Уйти',
                cancel: 'Отмена',
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool editing) {
    if (_missing != null) {
      return Center(child: Text(_missing!));
    }
    final initial = _initial;
    if (initial == null) {
      return const Center(child: Text('Загрузка записи…'));
    }
    final controller = context.read<CatalogController>();
    return SpecForm(
      key: _formKey,
      specs: specsFor(widget.kind, controller.store),
      initial: initial,
      submitLabel: editing ? 'Сохранить' : 'Создать',
      showErrors: widget.preview == 'invalid',
      serverErrors: _serverErrors,
      onChanged: () => _dirty = true,
      onSubmit: _submit,
    );
  }
}
