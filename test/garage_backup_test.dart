import 'package:flutter_test/flutter_test.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:gta6_dream_cars/services/garage_backup.dart';

void main() {
  test('round-trips the garage cars', () {
    const car = Car(id: 'test-car', nom: 'Test Car', marque: 'Test', possedee: true, dlc: 'Test DLC');

    final restored = GarageBackup.decode(GarageBackup.encode([car]), maxCars: 18).single;

    expect(restored.id, car.id);
    expect(restored.nom, car.nom);
    expect(restored.possedee, isTrue);
    expect(restored.dlc, car.dlc);
  });

  test('rejects backups that exceed garage capacity', () {
    const cars = [Car(id: 'one', nom: 'One', marque: 'Test', possedee: false), Car(id: 'two', nom: 'Two', marque: 'Test', possedee: false)];

    expect(() => GarageBackup.decode(GarageBackup.encode(cars), maxCars: 1), throwsFormatException);
  });
}
