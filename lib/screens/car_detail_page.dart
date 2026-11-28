import 'package:gta6_dream_cars/main.dart';
import 'package:gta6_dream_cars/screens/edit_car_page.dart';
import 'package:gta6_dream_cars/utils/routeur.dart';
import 'package:gta6_dream_cars/widgets/info_row.dart';
import 'package:gta6_dream_cars/widgets/ranking_row.dart';
import 'package:gta6_dream_cars/widgets/rating_row.dart';
import 'package:gta6_dream_cars/widgets/section_title.dart';
import 'package:gta6_dream_cars/widgets/tag.dart';
import 'package:material_ui/material_ui.dart';

import '../models/car.dart';
import '../widgets/car_image.dart';

class CarDetailPage extends StatefulWidget {
  const CarDetailPage({
    super.key,
    required this.cars,
    this.existingCarIds,
    required this.initialIndex,
    required this.onPossessionChanged,
    this.onRemove,
    this.onToggle,
    this.onEdit,
  });

  final List<Car> cars;
  final Set<String>? existingCarIds;
  final int initialIndex;
  final Future<bool> Function(String, bool) onPossessionChanged;
  final Future<bool> Function(String)? onRemove;
  final Future<bool> Function(Car)? onToggle;
  final Future<bool> Function(Car)? onEdit;

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  // -------------------------------------------------------------------------------------------------
  // | STATES

  late final List<Car> _cars = List.of(widget.cars);
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late final Set<String> _garageCarIds = {...?widget.existingCarIds};
  late int _currentIndex = widget.initialIndex;
  bool _isSaving = false;

  // -------------------------------------------------------------------------------------------------
  // | LIFECYCLE

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------------------------------
  // | METHODS

  Future<void> _confirmAndRemove(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette voiture ?'),
        content: Text('« ${car.nom} » sera retirée de ton garage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final removed = await widget.onRemove!(car.id);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (removed) Navigator.of(context).pop();
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePossession(Car car, bool value) async {
    setState(() => _isSaving = true);
    try {
      final saved = await widget.onPossessionChanged(car.id, value);
      if (!mounted) return;
      setState(() {
        if (saved) {
          final index = _cars.indexWhere((item) => item.id == car.id);
          if (index != -1) {
            _cars[index] = _cars[index].copyWith(possedee: value);
          }
        }
        _isSaving = false;
      });
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleGarageStatus(Car car) async {
    if (_isSaving || widget.onToggle == null) return;

    setState(() => _isSaving = true);
    try {
      final wasInGarage = _garageCarIds.contains(car.id);
      final updated = await widget.onToggle!(car);
      if (!mounted) return;
      setState(() {
        if (updated) {
          if (wasInGarage) {
            _garageCarIds.remove(car.id);
          } else {
            _garageCarIds.add(car.id);
            final index = _cars.indexWhere((item) => item.id == car.id);
            if (index != -1) {
              _cars[index] = _cars[index].copyWith(possedee: false);
            }
          }
        }
        _isSaving = false;
      });
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  Future<void> _editCar(Car car) async {
    final updatedCar = await Navigator.of(context).push<Car>(garagePageRoute<Car>(EditCarPage(car: car)));
    if (updatedCar == null || !mounted || widget.onEdit == null) return;

    setState(() => _isSaving = true);
    try {
      final saved = await widget.onEdit!(updatedCar);
      if (!mounted) return;
      setState(() {
        if (saved) {
          final index = _cars.indexWhere((item) => item.id == updatedCar.id);
          if (index != -1) _cars[index] = updatedCar;
        }
        _isSaving = false;
      });
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  // -------------------------------------------------------------------------------------------------
  // | WIDGETS

  Widget _buildCarDetails(Car car) {
    return ListView(
      key: PageStorageKey<String>('car-detail-${car.id}'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: AspectRatio(aspectRatio: 1.65, child: CarImage(car: car)),
            ),
            if (car.categorie != null) Positioned(top: 8, right: 8, child: Tag(label: car.categorie!.toUpperCase(), textSize: 14)),
            Positioned(top: 8, left: 8, child: CarBrandLogo(car: car, size: 30)),
            if (car.unique)
              Positioned(
                bottom: 5,
                right: 5,
                child: Tag(label: "Remarquable", color: Color.fromARGB(153, 255, 191, 0), textSize: 14),
              ),
            if (car.dlc != null)
              Positioned(
                bottom: 5,
                left: 5,
                child: Tag(label: car.dlc!, color: Color.fromARGB(153, 189, 0, 0), textSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                car.marque.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 25, color: Color.fromARGB(255, 167, 167, 167)),
              ),
            ),
          ],
        ),
        Text(car.nom.toUpperCase(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 12),
        Material(
          color: const Color.fromARGB(98, 12, 13, 27),
          child: Row(
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.only(left: 15), child: Text('Possédée'.toUpperCase())),
              ),
              Transform.scale(
                scale: 0.6,
                child: Switch(
                  key: ValueKey('detail-ownership-${car.id}'),
                  value: car.possedee,
                  onChanged: _isSaving || !_garageCarIds.contains(car.id) ? null : (value) => _changePossession(car, value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: pink,
                  trackOutlineColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.disabled) ? Colors.grey : Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('CARACTÉRISTIQUES'),
        Container(
          decoration: BoxDecoration(color: const Color.fromARGB(98, 12, 13, 27)),
          child: Column(
            children: [
              InfoRow('Accès', car.access),
              InfoRow('Sécurité', car.securite.toString()),
              InfoRow('Traceur', car.tracker),
              InfoRow('Style', car.style),
              InfoRow('Nombre de places', car.nombrePlaces?.toString(), isLast: car.modeleBase == null),
              if (car.modeleBase != null) InfoRow('Modèle de base', car.modeleBase, isLast: car.modeleBase != null),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('PERFORMANCES'),
        Container(
          decoration: BoxDecoration(color: const Color.fromARGB(98, 12, 13, 27)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RankingRow(routeRank: car.classementRoute, terrainRank: car.classementTerre),
                SizedBox(height: 16),
                RatingRow('Vitesse', car.stats?.vitesse),
                RatingRow('Accélération', car.stats?.acceleration),
                RatingRow('Adhérence asphalte', car.stats?.adherenceAsphalte),
                RatingRow('Adhérence terre', car.stats?.adherenceTerre),
                RatingRow('Robustesse', car.stats?.robustesse, isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------------------------------
  // | WIDGETS

  @override
  Widget build(BuildContext context) {
    final currentCar = _cars[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('FICHE VÉHICULE'),
        actions: [
          if (widget.onRemove != null)
            IconButton(
              tooltip: 'Supprimer de la liste',
              onPressed: _isSaving ? null : () => _confirmAndRemove(_cars[_currentIndex]),
              icon: Icon(Icons.delete_outline, color: Colors.white),
            ),
          if (widget.onToggle != null)
            IconButton(
              tooltip: _garageCarIds.contains(currentCar.id) ? 'Supprimer de la liste' : 'Ajouter à la liste',
              onPressed: _isSaving ? null : () => _toggleGarageStatus(currentCar),
              icon: Icon(_garageCarIds.contains(currentCar.id) ? Icons.delete_outline : Icons.add_circle_outline, color: Colors.white),
            ),

          if (editionMode.value && widget.onEdit != null)
            IconButton(
              tooltip: 'Editer',
              onPressed: _isSaving ? null : () => _editCar(currentCar),
              icon: Icon(Icons.edit, color: Colors.white),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _cars.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => _buildCarDetails(_cars[index]),
      ),
    );
  }

  // -------------------------------------------------------------------------------------------------
}
