import 'package:flutter/material.dart';

import 'field_spec.dart';

/// Общая форма: набор полей задаётся списком, отправка одна на все сущности.
class SpecForm extends StatefulWidget {
  const SpecForm({
    super.key,
    required this.specs,
    required this.initial,
    required this.onSubmit,
    required this.onChanged,
    this.submitLabel = 'Сохранить',
    this.showErrors = false,
    this.serverErrors = const {},
  });

  final List<FieldSpec> specs;
  final Map<String, Object?> initial;
  final Future<void> Function(Map<String, Object?> values) onSubmit;
  final VoidCallback onChanged;
  final String submitLabel;
  final bool showErrors;
  final Map<String, String> serverErrors;

  @override
  State<SpecForm> createState() => SpecFormState();
}

class SpecFormState extends State<SpecForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late Map<String, Object?> _values;
  var _saving = false;
  final _serverErrors = <String, String>{};

  Map<String, Object?> get values => _values;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final entry in widget.initial.entries)
        entry.key: entry.value is List ? List<int>.from(entry.value as List) : entry.value,
    };
    for (final spec in widget.specs) {
      if (_isText(spec.kind)) {
        _controllers[spec.key] = TextEditingController(text: '${_values[spec.key] ?? ''}');
      }
    }
    _serverErrors.addAll(widget.serverErrors);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  void applyServerErrors(Map<String, String> errors) {
    setState(() {
      _serverErrors
        ..clear()
        ..addAll(errors);
    });
    _formKey.currentState?.validate();
  }

  String? _check(FieldSpec spec) => _serverErrors[spec.key] ?? spec.validate?.call(_values);

  Future<void> submit() => _submit();

  bool _isText(FieldKind kind) =>
      kind == FieldKind.text ||
      kind == FieldKind.number ||
      kind == FieldKind.email ||
      kind == FieldKind.date;

  void _touch() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _submit() async {
    if (!validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_values);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ..._blocks(),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Сохранение…' : widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _blocks() {
    final blocks = <Widget>[];
    var index = 0;
    while (index < widget.specs.length) {
      final spec = widget.specs[index];
      if (spec.kind == FieldKind.section) {
        final nested = <Widget>[];
        index++;
        while (index < widget.specs.length && widget.specs[index].kind != FieldKind.section) {
          nested.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _field(widget.specs[index]),
          ));
          index++;
        }
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Column(children: nested),
            ),
          ),
        );
      } else {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _field(spec),
        ));
        index++;
      }
    }
    return blocks;
  }

  Widget _field(FieldSpec spec) {
    if (_isText(spec.kind)) {
      final forced = widget.showErrors || _serverErrors.containsKey(spec.key) ? _check(spec) : null;
      return TextFormField(
        controller: _controllers[spec.key],
        forceErrorText: forced,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          errorMaxLines: 3,
        ).copyWith(labelText: spec.label),
        keyboardType: spec.kind == FieldKind.number
            ? TextInputType.number
            : spec.kind == FieldKind.email
            ? TextInputType.emailAddress
            : TextInputType.text,
        onChanged: (value) {
          _values[spec.key] = value;
          _serverErrors.remove(spec.key);
          widget.onChanged();
        },
        validator: (_) => _check(spec),
      );
    }
    if (spec.kind == FieldKind.dropdown) {
      final options = spec.options?.call(_values) ?? const <LookupOption>[];
      final current = _values[spec.key];
      final selected = options.any((option) => option.id == current) ? current as int? : null;
      final forced = widget.showErrors || _serverErrors.containsKey(spec.key) ? _check(spec) : null;
      return DropdownButtonFormField<int>(
        key: ValueKey('${spec.key}-$selected'),
        initialValue: selected,
        isExpanded: true,
        forceErrorText: forced,
        decoration: InputDecoration(
          labelText: spec.label,
          border: const OutlineInputBorder(),
          errorMaxLines: 3,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option.id, child: Text(option.label)),
        ],
        onChanged: (value) {
          _values[spec.key] = value;
          _keepOnlyOfferedChips();
          _touch();
        },
        validator: (_) => _check(spec),
      );
    }
    final options = spec.options?.call(_values) ?? const <LookupOption>[];
    final optionKey = options.map((option) => option.id).join(',');
    final forced = widget.showErrors || _serverErrors.containsKey(spec.key) ? _check(spec) : null;
    return FormField<List<int>>(
      key: ValueKey('${spec.key}-$optionKey'),
      forceErrorText: forced,
      initialValue: _idList(_values[spec.key]).where(
        (id) => options.any((option) => option.id == id),
      ).toList(),
      validator: (value) {
        _values[spec.key] = value ?? <int>[];
        return _check(spec);
      },
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: spec.label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
            errorMaxLines: 3,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  FilterChip(
                    label: Text(option.label),
                    selected: field.value!.contains(option.id),
                    onSelected: (_) {
                      final next = [...field.value!];
                      if (!next.remove(option.id)) {
                        next.add(option.id);
                      }
                      field.didChange(next);
                      _values[spec.key] = next;
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _keepOnlyOfferedChips() {
    for (final spec in widget.specs.where((item) => item.kind == FieldKind.chips)) {
      final options = spec.options?.call(_values) ?? const <LookupOption>[];
      final allowed = options.map((option) => option.id).toSet();
      _values[spec.key] = _idList(_values[spec.key]).where(allowed.contains).toList();
    }
    for (final spec in widget.specs.where((item) => item.kind == FieldKind.dropdown)) {
      final options = spec.options?.call(_values) ?? const <LookupOption>[];
      final current = _values[spec.key];
      if (current is int && !options.any((option) => option.id == current)) {
        _values[spec.key] = null;
      }
    }
  }

  List<int> _idList(Object? value) {
    if (value is List<int>) {
      return value;
    }
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return const [];
  }
}
