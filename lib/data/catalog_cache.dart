import '../models/body_type.dart';
import '../models/brand.dart';
import '../models/option.dart';
import '../models/session.dart';

/// Справочники читаются один раз и дальше берутся отсюда.
/// Списки страниц здесь не лежат: страница каждый раз приходит с сервера.
class CatalogCache {
  List<Brand> brands = [];
  List<BodyType> bodyTypes = [];
  List<Option> options = [];
  Session? session;
  String? notice;
  var ready = false;

  List<Brand> liveBrands() => brands.where((item) => !item.isDeleted).toList();

  List<BodyType> liveBodyTypes() => bodyTypes.where((item) => !item.isDeleted).toList();

  List<Option> liveOptions() => options.where((item) => !item.isDeleted).toList();

  List<String> brandCountries() {
    final values = liveBrands().map((item) => item.country).toSet().toList();
    values.sort();
    return values;
  }

  List<BodyType> bodiesForBrand(int? brandId) {
    if (brandId == null) {
      return liveBodyTypes();
    }
    final allowed = brandById(brandId)?.bodyTypeIds.toSet() ?? const <int>{};
    return liveBodyTypes().where((item) => allowed.contains(item.id)).toList();
  }

  List<Option> optionsForBrand(int? brandId) {
    if (brandId == null) {
      return liveOptions();
    }
    final allowed = brandById(brandId)?.optionIds.toSet() ?? const <int>{};
    return liveOptions().where((item) => allowed.contains(item.id)).toList();
  }

  String brandName(int id) => brandById(id)?.name ?? '—';

  String bodyName(int id) => bodyById(id)?.name ?? '—';

  String optionNames(List<int> ids) => _join(ids, (id) => optionById(id)?.name);

  String bodyNameList(List<int> ids) => _join(ids, (id) => bodyById(id)?.name);

  Brand? brandById(int id) => _first(brands, (item) => item.id == id);

  BodyType? bodyById(int id) => _first(bodyTypes, (item) => item.id == id);

  Option? optionById(int id) => _first(options, (item) => item.id == id);

  void replace({
    required List<Brand> brands,
    required List<BodyType> bodyTypes,
    required List<Option> options,
  }) {
    this.brands = brands;
    this.bodyTypes = bodyTypes;
    this.options = options;
    ready = true;
  }

  T? _first<T>(List<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  String _join(List<int> ids, String? Function(int id) nameOf) {
    final names = [for (final id in ids) nameOf(id)].whereType<String>().toList();
    return names.isEmpty ? '—' : names.join(', ');
  }
}
