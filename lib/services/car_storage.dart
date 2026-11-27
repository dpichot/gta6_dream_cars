import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';

class CarStorage {
  static const _storageKey = 'garage_cars';
  static const _filtersStorageKey = 'garage_filters';

  Future<List<Car>> loadCars() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCars = preferences.getString(_storageKey);
    if (savedCars == null) return [];

    final decodedCars = jsonDecode(savedCars) as List<dynamic>;
    return decodedCars.map((car) => Car.fromJson(Map<String, dynamic>.from(car as Map))).toList();
  }

  Future<({String sortBy, String? groupBy})> loadFilters() async {
    final preferences = await SharedPreferences.getInstance();
    final savedFilters = preferences.getString(_filtersStorageKey);
    if (savedFilters == null) return (sortBy: 'name', groupBy: null);

    final decodedFilters = jsonDecode(savedFilters);
    if (decodedFilters is! Map<String, dynamic>) {
      throw const FormatException('Les filtres enregistrés sont invalides.');
    }

    final sortByValue = decodedFilters['sortBy'];
    final groupByValue = decodedFilters['groupBy'];
    if (sortByValue is! String) {
      throw const FormatException('Les filtres enregistrés sont invalides.');
    }

    final String? groupBy;
    if (groupByValue == null) {
      groupBy = null;
    } else if (groupByValue is String) {
      groupBy = groupByValue;
    } else {
      throw const FormatException('Les filtres enregistrés sont invalides.');
    }

    final sortBy = sortByValue;
    return (sortBy: sortBy, groupBy: groupBy);
  }

  Future<void> saveFilters({required String sortBy, required String? groupBy}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_filtersStorageKey, jsonEncode({'sortBy': sortBy, 'groupBy': groupBy}));
    if (!saved) {
      throw StateError('Le stockage local a refusé la sauvegarde des filtres.');
    }
  }

  Future<void> saveCars(List<Car> cars) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_storageKey, jsonEncode(cars.map((car) => car.toJson()).toList()));
    if (!saved) {
      throw StateError('Le stockage local a refusé la sauvegarde du garage.');
    }
  }

  Future<void> clearCars() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(_storageKey)) return;

    final removed = await preferences.remove(_storageKey);
    if (!removed) {
      throw StateError('Le stockage local a refusé la suppression du garage.');
    }
  }
}
