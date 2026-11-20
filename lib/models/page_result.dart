/// Одна страница списка: записи, номер, размер и общее число.
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int size;
  final int total;

  int get totalPages {
    if (size <= 0 || total == 0) {
      return 1;
    }
    return (total / size).ceil();
  }

  bool get hasPrevious => page > 1;

  bool get hasNext => page < totalPages;

  /// Пустая страница — начальное значение экрана.
  ///
  /// Конструктор не const: константный пустой список с параметром типа
  /// в Dart запрещён.
  PageResult.empty()
    : items = <T>[],
      page = 1,
      size = 10,
      total = 0;
}
