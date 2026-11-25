# Vice City Garage

Application Flutter de garage inspirée de GTA 6. Le garage s’ouvre au lancement,
permet d’ajouter les véhicules souhaités depuis la recherche, puis de les marquer
comme acquis ou non avec leur interrupteur. La collection est conservée sur
l’appareil avec `shared_preferences`.

Les fiches véhicule regroupent catégorie, sécurité, classe, style, nombre de
places, classements route/terre, modèle de base et statistiques de performance.
Les classements sont des entiers entre 1 et 999 ; les statistiques de test sont
des notes décimales entre 1 et 10 affichées sous forme de sliders en lecture
seule. Les caractéristiques encore inconnues sont indiquées comme non renseignées.
Les images des voitures et logos de marques sont chargés depuis `assets/`.

## Lancer l’application

```sh
flutter pub get
flutter run
```

Les véhicules du catalogue peuvent être recherchés par nom ou par marque. La
recherche utilise les miniatures ; le garage affiche une grille à deux colonnes
et chaque voiture ouvre sa fiche détaillée.

## Vérifier le projet

```sh
flutter test
flutter analyze
```
