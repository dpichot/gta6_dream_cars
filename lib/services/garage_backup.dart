import 'dart:convert';
import 'dart:typed_data';

import '../models/car.dart';

class GarageBackup {
  static const _format = 'dream-garage-backup';
  static const _version = 1;

  static Uint8List encode(List<Car> cars) {
    final backup = {
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'cars': cars.map((car) => car.toJson()).toList(),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(backup)));
  }

  static List<Car> decode(Uint8List bytes, {required int maxCars}) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['format'] != _format || decoded['version'] != _version) {
      throw const FormatException('Le fichier ne contient pas une sauvegarde reconnue.');
    }

    final rawCars = decoded['cars'];
    if (rawCars is! List) {
      throw const FormatException('La sauvegarde ne contient pas de liste de voitures valide.');
    }
    if (rawCars.length > maxCars) {
      throw FormatException('La sauvegarde dépasse la limite de $maxCars voitures.');
    }

    final cars = <Car>[];
    final carIds = <String>{};
    for (final rawCar in rawCars) {
      if (rawCar is! Map) {
        throw const FormatException('La sauvegarde contient une voiture invalide.');
      }
      final car = Car.fromJson(Map<String, dynamic>.from(rawCar));
      if (car.id.trim().isEmpty || !carIds.add(car.id)) {
        throw const FormatException('La sauvegarde contient un identifiant de voiture vide ou en double.');
      }
      cars.add(car);
    }

    return cars;
  }
}
