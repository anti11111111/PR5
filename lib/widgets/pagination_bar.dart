import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPage,
    required this.onSize,
  });

  final int page;
  final int totalPages;
  final int total;
  final int size;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            _pageButton(
              tooltip: 'Первая страница',
              onPressed: page > 1 ? () => onPage(1) : null,
              icon: Icons.first_page,
            ),
            _pageButton(
              tooltip: 'Предыдущая страница',
              onPressed: page > 1 ? () => onPage(page - 1) : null,
              icon: Icons.chevron_left,
            ),
            Text('Страница $page из $totalPages'),
            _pageButton(
              tooltip: 'Следующая страница',
              onPressed: page < totalPages ? () => onPage(page + 1) : null,
              icon: Icons.chevron_right,
            ),
            _pageButton(
              tooltip: 'Последняя страница',
              onPressed: page < totalPages ? () => onPage(totalPages) : null,
              icon: Icons.last_page,
            ),
            const SizedBox(width: 8),
            Text('Всего: $total'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: size,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSize(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton({
    required String tooltip,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
