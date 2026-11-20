/// Условия списка. Целиком попадают в адрес страницы.
class ListQuery {
  const ListQuery({
    this.search = '',
    this.brandId,
    this.bodyTypeId,
    this.yearFrom,
    this.yearTo,
    this.country,
    this.sortField = 'model',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.demoError = false,
    this.previewLoading = false,
  });

  final String search;
  final int? brandId;
  final int? bodyTypeId;
  final int? yearFrom;
  final int? yearTo;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  final bool demoError;
  final bool previewLoading;

  static const _allowedSize = {10, 25, 50};
  static const _unset = Object();

  ListQuery copyWith({
    String? search,
    Object? brandId = _unset,
    Object? bodyTypeId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? demoError,
    bool? previewLoading,
  }) {
    return ListQuery(
      search: search ?? this.search,
      brandId: brandId == _unset ? this.brandId : brandId as int?,
      bodyTypeId: bodyTypeId == _unset ? this.bodyTypeId : bodyTypeId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      demoError: demoError ?? this.demoError,
      previewLoading: previewLoading ?? this.previewLoading,
    );
  }

  factory ListQuery.fromUri(
    Uri uri, {
    required Set<String> allowedSort,
    required String defaultSort,
  }) {
    final params = uri.queryParameters;
    final sort = (params['sort'] ?? '$defaultSort,asc').split(',');
    final field = sort.isNotEmpty ? sort.first : defaultSort;
    final rawSize = int.tryParse(params['size'] ?? '') ?? 10;
    final rawPage = int.tryParse(params['page'] ?? '') ?? 1;
    final country = params['country'];
    return ListQuery(
      search: params['search'] ?? '',
      brandId: int.tryParse(params['brandId'] ?? ''),
      bodyTypeId: int.tryParse(params['bodyTypeId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      country: (country == null || country.isEmpty) ? null : country,
      sortField: allowedSort.contains(field) ? field : defaultSort,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: rawPage < 1 ? 1 : rawPage,
      size: _allowedSize.contains(rawSize) ? rawSize : 10,
      includeDeleted: params['includeDeleted'] == '1',
      demoError: params['demoError'] == '1',
      previewLoading: params['previewLoading'] == '1',
    );
  }

  Map<String, String> toParams() {
    return {
      if (search.isNotEmpty) 'search': search,
      if (brandId != null) 'brandId': '$brandId',
      if (bodyTypeId != null) 'bodyTypeId': '$bodyTypeId',
      if (yearFrom != null) 'yearFrom': '$yearFrom',
      if (yearTo != null) 'yearTo': '$yearTo',
      if (country != null && country!.isNotEmpty) 'country': country!,
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
      'page': '$page',
      'size': '$size',
      if (includeDeleted) 'includeDeleted': '1',
      if (demoError) 'demoError': '1',
      if (previewLoading) 'previewLoading': '1',
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ListQuery &&
        other.search == search &&
        other.brandId == brandId &&
        other.bodyTypeId == bodyTypeId &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.country == country &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted &&
        other.demoError == demoError &&
        other.previewLoading == previewLoading;
  }

  @override
  int get hashCode => Object.hash(
    search,
    brandId,
    bodyTypeId,
    yearFrom,
    yearTo,
    country,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
    demoError,
    previewLoading,
  );
}
