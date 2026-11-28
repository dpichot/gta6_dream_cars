import 'package:flutter_test/flutter_test.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:gta6_dream_cars/screens/edit_car_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('le formulaire retourne les informations modifiées', (tester) async {
    final car = Car(id: 'test-car', nom: 'Voiture originale', marque: 'Marque', possedee: true, categorie: 'Sport');
    Car? editedCar;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                editedCar = await Navigator.of(context).push<Car>(MaterialPageRoute<Car>(builder: (_) => EditCarPage(car: car)));
              },
              child: const Text('Modifier'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('MODIFIER LA VOITURE'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Voiture mise à jour');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(editedCar?.nom, 'Voiture mise à jour');
    expect(editedCar?.categorie, 'Sport');
    expect(editedCar?.possedee, isTrue);
    expect(editedCar?.detailsEdited, isTrue);
  });
}
