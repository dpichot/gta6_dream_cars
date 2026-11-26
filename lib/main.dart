import 'package:material_ui/material_ui.dart';

import 'data/car_catalog.dart';
import 'models/car.dart';
import 'screens/car_detail_page.dart';
import 'screens/search_car_page.dart';
import 'services/car_storage.dart';
import 'widgets/blurred_modal_bottom_sheet.dart';
import 'widgets/car_image.dart';
import 'widgets/garage_background.dart';
import 'widgets/gradient_button.dart';

enum _CarSort { ownership, name, brand, category }

enum _CarGroup { ownership, brand, category }

const pink = Color.fromARGB(255, 247, 120, 175);
const turquoise = Color(0xFF22CBB5);
const maxGarageCars = 18;

void main() {
  runApp(const GarageApp());
}

class GarageApp extends StatelessWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vice City Garage',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => GarageBackground(child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pink,
          brightness: Brightness.dark,
        ).copyWith(primary: pink, secondary: turquoise, surface: const Color.fromARGB(255, 28, 35, 65)),
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

PageRouteBuilder<T> _garagePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => GarageBackground(child: page),
    transitionsBuilder: (_, animation, _, child) {
      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);
      final slideAnimation = Tween<Offset>(begin: const Offset(0, .5), end: Offset.zero).animate(curvedAnimation);

      return SlideTransition(position: slideAnimation, child: child);
    },
  );
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
  _CarSort _sortBy = _CarSort.name;
  _CarGroup? _groupBy;
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
      final cars = savedCars.map((car) => catalogById[car.id] == null ? car : car.withDefaultsFrom(catalogById[car.id]!)).toList();
      var sortBy = _CarSort.name;
      _CarGroup? groupBy;
      Object? filterLoadError;
      try {
        final savedFilters = await _storage.loadFilters();
        sortBy = _CarSort.values.byName(savedFilters.sortBy);
        final savedGroupBy = savedFilters.groupBy;
        groupBy = savedGroupBy == null ? null : _CarGroup.values.byName(savedGroupBy);
      } catch (error) {
        sortBy = _CarSort.name;
        groupBy = null;
        filterLoadError = error;
      }

      if (!mounted) return;
      setState(() {
        _cars = cars;
        _sortBy = sortBy;
        _groupBy = groupBy;
        _isLoading = false;
        _loadError = null;
      });
      if (filterLoadError != null) _showFilterLoadError(filterLoadError);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible de charger le garage : $error';
      });
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      _garagePageRoute<void>(
        SearchCarPage(existingCarIds: _cars.map((car) => car.id).toSet(), garageCapacity: maxGarageCars, onAddCar: _addCar, onRemoveCar: _removeCar),
      ),
    );
  }

  Future<bool> _addCar(Car car) async {
    if (_cars.length >= maxGarageCars) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La liste est limitée à 18 voitures.')));
      return false;
    }
    final updatedCars = [..._cars, car.copyWith(possedee: false)];
    try {
      await _storage.saveCars(updatedCars);
      if (!mounted) return false;
      setState(() => _cars = updatedCars);
      return true;
    } catch (error) {
      if (!mounted) return false;
      _showSaveError(error);
      return false;
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

  Future<void> filter() async {
    var selectedSort = _sortBy;
    var selectedGroup = _groupBy;
    final options = await showBlurredModalBottomSheet<({_CarSort sortBy, _CarGroup? groupBy})>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: filterSheetDecoration,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  SectionTitle('TRIÉ PAR :'),
                  DropdownButtonFormField<_CarSort>(
                    initialValue: selectedSort,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: _CarSort.ownership, child: Text('Statut (possédée)')),
                      DropdownMenuItem(value: _CarSort.name, child: Text('Nom')),
                      DropdownMenuItem(value: _CarSort.brand, child: Text('Marque')),
                      DropdownMenuItem(value: _CarSort.category, child: Text('Catégorie')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedSort = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SectionTitle('GROUPÉ PAR :'),
                  DropdownButtonFormField<_CarGroup?>(
                    initialValue: selectedGroup,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Aucun')),
                      DropdownMenuItem(value: _CarGroup.ownership, child: Text('Statut (possédée)')),
                      DropdownMenuItem(value: _CarGroup.brand, child: Text('Marque')),
                      DropdownMenuItem(value: _CarGroup.category, child: Text('Catégorie')),
                    ],
                    onChanged: (value) {
                      setSheetState(() => selectedGroup = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    onPressed: () => Navigator.pop(sheetContext, (sortBy: selectedSort, groupBy: selectedGroup)),
                    icon: Icons.done,
                    label: 'Appliquer',
                    height: 40,
                  ),
                  // FilledButton(
                  //   onPressed: () => Navigator.pop(sheetContext, (sortBy: selectedSort, groupBy: selectedGroup)),
                  //   child: const Text('Appliquer'),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (options == null || !mounted) return;
    try {
      await _storage.saveFilters(sortBy: options.sortBy.name, groupBy: options.groupBy?.name);
      if (!mounted) return;
      setState(() {
        _sortBy = options.sortBy;
        _groupBy = options.groupBy;
      });
    } catch (error) {
      if (mounted) _showFilterSaveError(error);
    }
  }

  int _compareCars(Car first, Car second) {
    final comparison = switch (_sortBy) {
      _CarSort.ownership =>
        first.possedee == second.possedee
            ? 0
            : first.possedee
            ? -1
            : 1,
      _CarSort.name => first.nom.toLowerCase().compareTo(second.nom.toLowerCase()),
      _CarSort.brand => first.marque.toLowerCase().compareTo(second.marque.toLowerCase()),
      _CarSort.category => _categoryName(first).toLowerCase().compareTo(_categoryName(second).toLowerCase()),
    };
    if (comparison != 0) return comparison;
    final nameComparison = first.nom.toLowerCase().compareTo(second.nom.toLowerCase());
    return nameComparison != 0 ? nameComparison : first.id.compareTo(second.id);
  }

  String _categoryName(Car car) {
    final category = car.categorie?.trim();
    return category == null || category.isEmpty ? 'Non catégorisée' : category;
  }

  List<({String name, List<Car> cars})> _getOrderedCarGroups() {
    final sortedCars = [..._cars]..sort(_compareCars);
    if (_groupBy == null) return [(name: '', cars: sortedCars)];

    final groupedCars = <String, List<Car>>{};
    for (final car in sortedCars) {
      final groupName = switch (_groupBy!) {
        _CarGroup.ownership => car.possedee ? 'Possédées' : 'Non possédées',
        _CarGroup.brand => car.marque,
        _CarGroup.category => _categoryName(car),
      };
      groupedCars.putIfAbsent(groupName, () => []).add(car);
    }

    final groupNames = groupedCars.keys.toList();
    groupNames.sort((first, second) {
      if (_groupBy == _CarGroup.ownership) {
        return first == second
            ? 0
            : first == 'Possédées'
            ? -1
            : 1;
      }
      return first.toLowerCase().compareTo(second.toLowerCase());
    });

    return [for (final groupName in groupNames) (name: groupName, cars: groupedCars[groupName]!)];
  }

  List<Car> _getDisplayedCars() => [for (final group in _getOrderedCarGroups()) ...group.cars];

  List<Widget> _buildCarSections() {
    final orderedGroups = _getOrderedCarGroups();
    if (_groupBy == null) return [_buildCarGrid(orderedGroups.single.cars)];

    return [
      for (var index = 0; index < orderedGroups.length; index++) ...[
        if (index > 0) const SizedBox(height: 20),
        Text(
          orderedGroups[index].name.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w600, color: pink),
        ),
        const SizedBox(height: 10),
        _buildCarGrid(orderedGroups[index].cars),
      ],
    ];
  }

  Widget _buildCarGrid(List<Car> cars) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 220,
      ),
      itemBuilder: (context, index) {
        final car = cars[index];
        return _GarageCarCard(
          car: car,
          isSaving: _savingCarIds.contains(car.id),
          onTap: () => _openDetails(car),
          onLongPress: () => _showCarActions(car),
          onPossessionChanged: (value) => _toggleOwnership(car.id, value),
        );
      },
    );
  }

  Future<void> _showCarActions(Car car) async {
    final action = await showBlurredModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 23, 26, 53), Color(0xFF191526), Color(0xFF0D0F16)],
            stops: [0, .48, 1],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(car.nom.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                // Container(
                //   color: const Color.fromARGB(98, 12, 13, 27),
                //   padding: EdgeInsets.all(8),
                //   child: ListTile(
                //     leading: Icon(Icons.remove_red_eye_outlined, color: Colors.white),
                //     title: Text('Voir les détails'.toUpperCase()),
                //     onTap: () => Navigator.pop(sheetContext, 'view'),
                //   ),
                // ),
                Container(
                  color: const Color.fromARGB(98, 12, 13, 27),
                  padding: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(car.possedee ? Icons.remove_circle_outline : Icons.check_circle_outline, color: Colors.white),
                    title: Text((car.possedee ? 'Marquer comme non possédée' : 'Marquer comme possédée').toUpperCase()),
                    onTap: () => Navigator.pop(sheetContext, 'toggle'),
                  ),
                ),
                Container(
                  color: const Color.fromARGB(98, 12, 13, 27),
                  padding: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.white),
                    title: Text('Supprimer du garage'.toUpperCase()),
                    onTap: () => Navigator.pop(sheetContext, 'delete'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'toggle') {
      await _toggleOwnership(car.id, !car.possedee);
    } else if (action == 'view') {
      await _openDetails(car);
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
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true && mounted) await _removeCar(car.id);
  }

  Future<bool> _toggleOwnership(String id, bool possedee) async {
    if (_savingCarIds.contains(id)) return false;
    final updatedCars = _cars.map((car) => car.id == id ? car.copyWith(possedee: possedee) : car).toList();
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
    final sortedCars = _getDisplayedCars();
    final initialIndex = sortedCars.indexWhere((item) => item.id == car.id);
    if (initialIndex == -1) return;

    await Navigator.of(context).push<void>(
      _garagePageRoute<void>(
        CarDetailPage(cars: sortedCars, initialIndex: initialIndex, onPossessionChanged: _toggleOwnership, onRemove: _removeCar),
      ),
    );
  }

  void _showSaveError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de sauvegarder la voiture : $error')));
  }

  void _showFilterLoadError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de charger les filtres : $error')));
  }

  void _showFilterSaveError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de sauvegarder les filtres : $error')));
  }

  @override
  Widget build(BuildContext context) {
    final acquiredCount = _cars.where((car) => car.possedee).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: filter,
        backgroundColor: Color(0xff23212e),
        child: Icon(Icons.filter_alt_outlined, color: pink),
      ),
      appBar: AppBar(
        title: Row(
          spacing: 10,
          children: [
            SizedBox(width: 35, height: 35, child: Image.asset("assets/images/garage.webp")),
            Text(
              'dream garage'.toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  GradientButton(onPressed: _openSearch, icon: Icons.search, label: 'Rechercher une voiture', height: 40),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 8,
                    children: [
                      ClassTag(textSize: 12, label: '${_cars.length} / 18 ${_cars.length == 1 ? 'voiture' : 'voitures'}'),
                      ClassTag(textSize: 12, label: '$acquiredCount possédée${acquiredCount == 1 ? '' : 's'}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_cars.isEmpty) const _EmptyGarage() else ..._buildCarSections(),
                  const SizedBox(height: 80),
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
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color.fromARGB(100, 12, 13, 27)),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      SizedBox(height: 110, child: CarImage(car: car)),
                      if (car.categorie != null) Positioned(top: 5, right: 5, child: ClassTag(label: car.categorie!)),
                      Positioned(top: 5, left: 5, child: CarBrandLogo(car: car, size: 18)),
                      if (car.unique)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: ClassTag(label: "Remarquable", color: Color.fromARGB(153, 255, 191, 0)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .5)),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          car.nom.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, height: 1.1, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (car.possedee ? 'Possédée' : 'Non possédée').toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  car.possedee
                      ? const Icon(Icons.check_circle, color: turquoise, size: 18)
                      : const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassTag extends StatelessWidget {
  const ClassTag({super.key, required this.label, this.color, this.textSize = 8});

  final String label;
  final Color? color;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? const Color.fromARGB(98, 12, 13, 27), borderRadius: BorderRadius.circular(0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w800, letterSpacing: .5),
        ),
      ),
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color.fromARGB(98, 12, 13, 27)),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.directions_car_filled_outlined, size: 44, color: pink),
            const SizedBox(height: 14),
            Text('Garage vide', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
