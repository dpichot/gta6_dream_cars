import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';

class CarStorage {
  static const _storageKey = 'garage_cars';

  Future<List<Car>> loadCars() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCars = preferences.getString(_storageKey);
    if (savedCars == null) return [];

    final decodedCars = jsonDecode(savedCars) as List<dynamic>;
    return decodedCars
        .map((car) => Car.fromJson(Map<String, dynamic>.from(car as Map)))
        .toList();
  }

  Future<void> saveCars(List<Car> cars) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(cars.map((car) => car.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Le stockage local a refusé la sauvegarde du garage.');
    }
  }
}
