import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gta6_dream_cars/services/car_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses the default filters when none are saved', () async {
    final filters = await CarStorage().loadFilters();

    expect(filters.sortBy, 'name');
    expect(filters.groupBy, isNull);
  });

  test('saves and restores the selected filters', () async {
    final storage = CarStorage();
    await storage.saveFilters(sortBy: 'brand', groupBy: 'category');

    final filters = await storage.loadFilters();

    expect(filters.sortBy, 'brand');
    expect(filters.groupBy, 'category');
  });

  test('saves no grouping as a null value', () async {
    final storage = CarStorage();
    await storage.saveFilters(sortBy: 'ownership', groupBy: null);

    final filters = await storage.loadFilters();

    expect(filters.sortBy, 'ownership');
    expect(filters.groupBy, isNull);
  });
}
