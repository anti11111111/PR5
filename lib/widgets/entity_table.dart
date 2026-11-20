import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });

  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;
}

/// Одна таблица для всех сущностей: колонки задаются снаружи.
class EntityTable<T> extends StatefulWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSelect = widget.onToggleSelect != null;
    final showActions = widget.actions != null;
    final sortIndex = widget.columns.indexWhere(
      (column) => column.sortField != null && column.sortField == widget.sortField,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _vertical,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _vertical,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortAscending: widget.sortAscending,
                    sortColumnIndex: sortIndex < 0
                        ? null
                        : sortIndex + (showSelect ? 1 : 0),
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      if (showSelect) const DataColumn(label: Text('')),
                      for (final column in widget.columns)
                        DataColumn(
                          label: Text(column.label),
                          numeric: column.numeric,
                          onSort: column.sortField == null || widget.onSort == null
                              ? null
                              : (_, _) => widget.onSort!(column.sortField!),
                        ),
                      if (showActions) const DataColumn(label: Text('Действия')),
                    ],
                    rows: [
                      for (final item in widget.items)
                        _row(context, item, showSelect, showActions),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(BuildContext context, T item, bool showSelect, bool showActions) {
    final id = widget.idOf(item);
    final deleted = widget.isDeleted?.call(item) ?? false;
    return DataRow(
      color: deleted
          ? const WidgetStatePropertyAll(Color(0xFFFFEBEE))
          : null,
      cells: [
        if (showSelect)
          DataCell(
            Checkbox(
              value: widget.selected.contains(id),
              onChanged: (_) => widget.onToggleSelect!(id),
            ),
          ),
        for (final column in widget.columns) DataCell(column.build(item)),
        if (showActions)
          DataCell(
            Row(mainAxisSize: MainAxisSize.min, children: widget.actions!(item)),
          ),
      ],
    );
  }
}
