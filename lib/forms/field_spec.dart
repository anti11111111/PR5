enum FieldKind { text, number, email, date, dropdown, chips, section }

class LookupOption {
  const LookupOption(this.id, this.label);

  final int id;
  final String label;
}

class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.kind,
    this.validate,
    this.options,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final String? Function(Map<String, Object?> values)? validate;
  final List<LookupOption> Function(Map<String, Object?> values)? options;
}

Map<String, Object?> emptyForm(List<FieldSpec> specs) {
  return {
    for (final spec in specs)
      if (spec.kind != FieldKind.section)
        spec.key: spec.kind == FieldKind.dropdown
            ? null
            : spec.kind == FieldKind.chips
            ? <int>[]
            : '',
  };
}
