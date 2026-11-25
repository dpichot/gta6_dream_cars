import 'package:material_ui/material_ui.dart';

import 'data/car_catalog.dart';
import 'models/car.dart';
import 'screens/car_detail_page.dart';
import 'screens/search_car_page.dart';
import 'services/car_storage.dart';
import 'widgets/car_image.dart';
import 'widgets/gradient_button.dart';

void main() {
  runApp(const GarageApp());
}

class GarageApp extends StatelessWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF4F9A);
    const turquoise = Color(0xFF53E0D0);

    return MaterialApp(
      title: 'Vice City Garage',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202449), Color(0xFF191526), Color(0xFF0D0F16)],
            stops: [0, .48, 1],
          ),
        ),
        child: child,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: pink,
              brightness: Brightness.dark,
            ).copyWith(
              primary: pink,
              secondary: turquoise,
              surface: const Color.fromARGB(255, 28, 35, 65),
            ),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF171922),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF292C38)),
          ),
        ),
      ),
      home: const GaragePage(),
    );
  }
}

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final CarStorage _storage = CarStorage();
  final Set<String> _savingCarIds = {};
  List<Car> _cars = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final savedCars = await _storage.loadCars();
      final catalogById = {for (final car in carCatalog) car.id: car};
      final cars = savedCars
          .map(
            (car) => catalogById[car.id] == null
                ? car
                : car.withDefaultsFrom(catalogById[car.id]!),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _cars = cars;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible de charger le garage : $error';
      });
    }
  }

  Future<void> _openSearch() async {
    final car = await Navigator.of(context).push<Car>(
      MaterialPageRoute(
        builder: (_) =>
            SearchCarPage(existingCarIds: _cars.map((car) => car.id).toSet()),
      ),
    );
    if (car == null || !mounted) return;
    if (_cars.any((item) => item.id == car.id)) {
      await _removeCar(car.id);
      return;
    }

    await _addCar(car);
  }

  Future<void> _addCar(Car car) async {
    final updatedCars = [..._cars, car.copyWith(possedee: false)];
    try {
      await _storage.saveCars(updatedCars);
      if (!mounted) return;
      setState(() => _cars = updatedCars);
    } catch (error) {
      if (!mounted) return;
      _showSaveError(error);
    }
  }

  Future<bool> _removeCar(String id) async {
    if (_savingCarIds.contains(id)) return false;
    final updatedCars = _cars.where((car) => car.id != id).toList();
    if (updatedCars.length == _cars.length) return false;
    setState(() => _savingCarIds.add(id));

    try {
      await _storage.saveCars(updatedCars);
      if (!mounted) return false;
      setState(() => _cars = updatedCars);
      return true;
    } catch (error) {
      if (mounted) _showSaveError(error);
      return false;
    } finally {
      if (mounted) setState(() => _savingCarIds.remove(id));
    }
  }

  Future<void> _showCarActions(Car car) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 28, 35, 65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  car.nom.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  car.possedee
                      ? Icons.remove_circle_outline
                      : Icons.check_circle_outline,
                  color: const Color(0xFF53E0D0),
                ),
                title: Text(
                  car.possedee
                      ? 'Marquer comme non possédée'
                      : 'Marquer comme possédée',
                ),
                onTap: () => Navigator.pop(sheetContext, 'toggle'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFF6B6B),
                ),
                title: const Text('Supprimer du garage'),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'toggle') {
      await _toggleOwnership(car.id, !car.possedee);
    } else if (action == 'delete') {
      await _confirmAndRemoveCar(car);
    }
  }

  Future<void> _confirmAndRemoveCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette voiture ?'),
        content: Text('« ${car.nom} » sera retirée de ton garage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          GradientButton(
            label: 'Supprimer',
            compact: true,
            height: 40,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _removeCar(car.id);
  }

  Future<bool> _toggleOwnership(String id, bool possedee) async {
    if (_savingCarIds.contains(id)) return false;
    final updatedCars = _cars
        .map((car) => car.id == id ? car.copyWith(possedee: possedee) : car)
        .toList();
    setState(() => _savingCarIds.add(id));

    try {
      await _storage.saveCars(updatedCars);
      if (!mounted) return false;
      setState(() => _cars = updatedCars);
      return true;
    } catch (error) {
      if (mounted) _showSaveError(error);
      return false;
    } finally {
      if (mounted) setState(() => _savingCarIds.remove(id));
    }
  }

  Future<void> _openDetails(Car car) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          car: car,
          onPossessionChanged: (value) => _toggleOwnership(car.id, value),
          onRemove: () => _removeCar(car.id),
        ),
      ),
    );
  }

  void _showSaveError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossible de sauvegarder la voiture : $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acquiredCount = _cars.where((car) => car.possedee).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 10,
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: Image.asset("assets/images/garage.webp"),
            ),
            Text(
              'dream garage'.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _LoadError(message: _loadError!, onRetry: _loadCars)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  GradientButton(
                    onPressed: _openSearch,
                    icon: Icons.search,
                    label: 'Rechercher une voiture',
                    height: 40,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 8,
                    children: [
                      ClassTag(
                        textSize: 12,
                        label:
                            '${_cars.length} ${_cars.length == 1 ? 'voiture' : 'voitures'}',
                      ),
                      ClassTag(
                        textSize: 12,
                        colors: [
                          const Color(0xFF53E0D0),
                          const Color(0xFF53E0D0),
                        ],
                        label:
                            '$acquiredCount possédée${acquiredCount == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                  // Text(
                  //   '${_cars.length} ${_cars.length == 1 ? 'voiture' : 'voitures'} · $acquiredCount acquise${acquiredCount == 1 ? '' : 's'}',
                  //   style: TextStyle(
                  //     color: Colors.white.withValues(alpha: .65),
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  if (_cars.isEmpty)
                    const _EmptyGarage()
                  else ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 220,
                          ),
                      itemBuilder: (context, index) {
                        final car = _cars[index];
                        return _GarageCarCard(
                          car: car,
                          isSaving: _savingCarIds.contains(car.id),
                          onTap: () => _openDetails(car),
                          onLongPress: () => _showCarActions(car),
                          onPossessionChanged: (value) =>
                              _toggleOwnership(car.id, value),
                        );
                      },
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _GarageCarCard extends StatelessWidget {
  const _GarageCarCard({
    required this.car,
    required this.isSaving,
    required this.onTap,
    required this.onLongPress,
    required this.onPossessionChanged,
  });

  final Car car;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onPossessionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color.fromARGB(98, 12, 13, 27)),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      SizedBox(height: 110, child: CarImage(car: car)),
                      // if (car.classe != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: ClassTag(label: car.categorie!),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: CarBrandLogo(car: car, size: 18),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                car.marque.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: .5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          car.nom.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Possédée'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTap,
                  child: car.possedee
                      ? const Icon(
                          Icons.check_box,
                          color: Color(0xFF22CBB5),
                          size: 18,
                        )
                      : const Icon(
                          Icons.check_box_outline_blank,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
                // Switch(
                //   key: ValueKey('ownership-${car.id}'),
                //   value: car.possedee,
                //   onChanged: isSaving ? null : onPossessionChanged,
                //   activeThumbColor: const Color(0xFF53E0D0),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClassTag extends StatelessWidget {
  const ClassTag({
    super.key,
    required this.label,
    this.colors,
    this.textSize = 8,
  });

  final String label;
  final List<Color>? colors;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color.fromARGB(98, 12, 13, 27),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.directions_car_filled_outlined,
              size: 44,
              color: Color(0xFFFF4F9A),
            ),
            const SizedBox(height: 14),
            Text(
              'Garage vide',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoute les voitures qui te font envie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .65)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GradientButton(label: 'Réessayer', onPressed: onRetry, height: 44),
          ],
        ),
      ),
    );
  }
}
