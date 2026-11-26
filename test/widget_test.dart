import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6_dream_cars/data/car_catalog.dart';
import 'package:gta6_dream_cars/main.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _toggleCarFromSearch(WidgetTester tester, Car car) async {
  await tester.tap(find.text('Rechercher une voiture'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('toggle-car-${car.id}')));
  await tester.pumpAndSettle();
  tester.state<NavigatorState>(find.byType(Navigator).last).pop();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ajouter une voiture ne la marque pas comme acquise', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();

    expect(find.text('DREAM GARAGE'), findsOneWidget);
    expect(find.text('Garage vide'), findsOneWidget);

    await _toggleCarFromSearch(tester, carCatalog.first);

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.text('1 VOITURE'), findsOneWidget);
    expect(find.text('0 POSSÉDÉES'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    var savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars.single['possédée'], isFalse);
    expect(savedCars.single['image'], 'assets/cars/comet-s2.jpg');
    expect(savedCars.single['nombrePlaces'], 2);

    await tester.longPress(find.text('COMET S2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme possédée'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars.single['possédée'], isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();

    expect(find.text('1 VOITURE'), findsOneWidget);
    expect(find.text('1 POSSÉDÉE'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    await tester.longPress(find.text('COMET S2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme non possédée'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars.single['possédée'], isFalse);
  });

  testWidgets('la recherche reste ouverte pendant les ajouts et suppressions', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher une voiture'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('toggle-car-${carCatalog.first.id}')));
    await tester.pumpAndSettle();
    expect(find.text('RECHERCHER'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('toggle-car-${carCatalog[1].id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('toggle-car-${carCatalog.first.id}')));
    await tester.pumpAndSettle();
    expect(find.text('RECHERCHER'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();

    expect(find.text('1 / 18 VOITURE'), findsOneWidget);
    expect(find.text(carCatalog[1].nom.toUpperCase()), findsOneWidget);
    expect(find.text(carCatalog.first.nom.toUpperCase()), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    final savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars.single['id'], carCatalog[1].id);
  });

  testWidgets('la fiche affiche les données et l’image du véhicule', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await _toggleCarFromSearch(tester, carCatalog[1]);
    await tester.tap(find.text("ANDREW NODE'S THRAX"));
    await tester.pumpAndSettle();

    expect(find.text('FICHE VÉHICULE'), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(find.byIcon(Icons.route), 250);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.route), findsOneWidget);
    expect(find.byIcon(Icons.terrain), findsOneWidget);
    expect(find.text('847'), findsOneWidget);
    expect(find.text('292'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('9.2'), 250);
    await tester.pumpAndSettle();
    expect(find.text('9.2'), findsOneWidget);
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders, hasLength(5));
    expect(sliders.first.value, 9.2);
    expect(sliders.every((slider) => slider.value >= 1 && slider.value <= 10), isTrue);
  });

  testWidgets('la fiche permet de swiper entre les voitures du garage', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await _toggleCarFromSearch(tester, carCatalog.first);
    await _toggleCarFromSearch(tester, carCatalog[1]);

    await tester.tap(find.text(carCatalog.first.nom.toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text(carCatalog.first.nom.toUpperCase()), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text(carCatalog[1].nom.toUpperCase()), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer de la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text(carCatalog.first.nom.toUpperCase()), findsOneWidget);
    expect(find.text(carCatalog[1].nom.toUpperCase()), findsNothing);
  });

  testWidgets('un retour de recherche supprime une voiture déjà listée', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await _toggleCarFromSearch(tester, carCatalog.first);
    expect(find.text('COMET S2'), findsOneWidget);

    await _toggleCarFromSearch(tester, carCatalog.first);
    await tester.pumpAndSettle();
    expect(find.text('Garage vide'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    final savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars, isEmpty);
  });

  testWidgets('un appui long propose possession et suppression', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await _toggleCarFromSearch(tester, carCatalog.first);

    await tester.longPress(find.text('COMET S2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme possédée'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    var savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars.single['possédée'], isTrue);

    await tester.longPress(find.text('COMET S2'));
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme non possédée'), findsOneWidget);
    await tester.tap(find.text('Supprimer du garage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Garage vide'), findsOneWidget);
    savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars, isEmpty);
  });

  testWidgets('la fiche permet de supprimer la voiture', (tester) async {
    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    await _toggleCarFromSearch(tester, carCatalog.first);
    await tester.tap(find.text('COMET S2'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer de la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Garage vide'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final savedCars = jsonDecode(preferences.getString('garage_cars')!) as List;
    expect(savedCars, isEmpty);
  });

  testWidgets('récupère les détails des voitures déjà sauvegardées', (tester) async {
    SharedPreferences.setMockInitialValues({
      'garage_cars': jsonEncode([
        {'id': 'pfister-comet-s2', 'nom': 'Comet S2', 'marque': 'Pfister', 'possédée': false},
      ]),
    });

    await tester.pumpWidget(const GarageApp());
    await tester.pumpAndSettle();
    expect(find.text('1 VOITURE'), findsOneWidget);
    expect(find.text('0 POSSÉDÉES'), findsOneWidget);
    await tester.ensureVisible(find.text('COMET S2'));
    await tester.tap(find.text('COMET S2'));
    await tester.pumpAndSettle();
    expect(find.text('FICHE VÉHICULE'), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });
}
