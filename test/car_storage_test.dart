import 'package:flutter_test/flutter_test.dart';
import 'package:gta6_dream_cars/data/car_catalog.dart';
import 'package:gta6_dream_cars/models/car.dart';
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

  test('clears only the saved garage', () async {
    SharedPreferences.setMockInitialValues({'garage_cars': '[{"id":"car"}]', 'garage_filters': '{"sortBy":"brand","groupBy":null}'});
    final storage = CarStorage();

    await storage.clearCars();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('garage_cars'), isNull);
    expect(preferences.getString('garage_filters'), '{"sortBy":"brand","groupBy":null}');
  });

  test('clearing an already empty garage is harmless', () async {
    await CarStorage().clearCars();
  });

  test('edited car details keep explicit empty values when defaults are merged', () {
    final catalogCar = carCatalog.first;
    final editedCar = Car.fromJson(
      Car(
        id: catalogCar.id,
        nom: 'Voiture personnalisée',
        marque: catalogCar.marque,
        possedee: false,
        unique: false,
        detailsEdited: true,
        imagePath: 'custom/cars/test-car.png',
      ).toJson(),
    );

    final restoredCar = editedCar.withDefaultsFrom(catalogCar);

    expect(restoredCar.nom, 'Voiture personnalisée');
    expect(restoredCar.categorie, isNull);
    expect(restoredCar.unique, isFalse);
    expect(restoredCar.imagePath, 'custom/cars/test-car.png');
  });
}
