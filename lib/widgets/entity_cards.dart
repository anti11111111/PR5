import 'package:flutter/material.dart';

/// Список карточек для узкого окна вместо таблицы.
class EntityCards<T> extends StatelessWidget {
  const EntityCards({
    super.key,
    required this.items,
    required this.idOf,
    required this.title,
    required this.subtitle,
    this.selected = const {},
    this.onToggleSelect,
    this.onOpen,
    this.actions,
    this.isDeleted,
  });

  final List<T> items;
  final int Function(T item) idOf;
  final Widget Function(T item) title;
  final Widget Function(T item) subtitle;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<T>? onOpen;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        final deleted = isDeleted?.call(item) ?? false;
        return Card(
          color: deleted ? const Color(0xFFFFEBEE) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggleSelect != null)
                  Checkbox(
                    value: selected.contains(id),
                    onChanged: (_) => onToggleSelect!(id),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: onOpen == null ? null : () => onOpen!(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title(item),
                          const SizedBox(height: 4),
                          subtitle(item),
                          if (deleted) ...[
                            const SizedBox(height: 6),
                            const Text('Скрыта'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (actions != null)
                  Column(mainAxisSize: MainAxisSize.min, children: actions!(item)),
              ],
            ),
          ),
        );
      },
    );
  }
}
