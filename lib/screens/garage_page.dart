import 'package:gta6_dream_cars/data/car_catalog.dart';
import 'package:gta6_dream_cars/main.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:gta6_dream_cars/screens/car_detail_page.dart';
import 'package:gta6_dream_cars/screens/search_car_page.dart';
import 'package:gta6_dream_cars/screens/settings_page.dart';
import 'package:gta6_dream_cars/services/car_storage.dart';
import 'package:gta6_dream_cars/utils/routeur.dart';
import 'package:gta6_dream_cars/widgets/blurred_modal_bottom_sheet.dart';
import 'package:gta6_dream_cars/widgets/car_card.dart';
import 'package:gta6_dream_cars/widgets/error_widget.dart';
import 'package:gta6_dream_cars/widgets/gradient_button.dart';
import 'package:gta6_dream_cars/widgets/section_title.dart';
import 'package:gta6_dream_cars/widgets/tag.dart';
import 'package:material_ui/material_ui.dart';

enum _CarSortFilters { ownership, name, brand, category }

enum _CarGroupFilters { ownership, brand, category }

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  // -------------------------------------------------------------------------------------------------
  // | STATES

  final CarStorage _storage = CarStorage();

  final Set<String> _savingCarIds = {};
  List<Car> _cars = [];

  _CarSortFilters _sortBy = _CarSortFilters.name;
  _CarGroupFilters? _groupBy;

  bool _isLoading = true;
  String? _loadError;

  // -------------------------------------------------------------------------------------------------
  // | LIFECYCLE

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  // -------------------------------------------------------------------------------------------------
  // | METHODS

  Future<void> _loadCars() async {
    try {
      final savedCars = await _storage.loadCars();
      final catalogById = {for (final car in carCatalog) car.id: car};
      final cars = savedCars.map((car) => catalogById[car.id] == null ? car : car.withDefaultsFrom(catalogById[car.id]!)).toList();
      var sortBy = _CarSortFilters.name;
      _CarGroupFilters? groupBy;
      Object? filterLoadError;
      try {
        final savedFilters = await _storage.loadFilters();
        sortBy = _CarSortFilters.values.byName(savedFilters.sortBy);
        final savedGroupBy = savedFilters.groupBy;
        groupBy = savedGroupBy == null ? null : _CarGroupFilters.values.byName(savedGroupBy);
      } catch (error) {
        sortBy = _CarSortFilters.name;
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

  Future<bool> _addCar(Car car) async {
    if (_cars.length >= maxGarageCars) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La liste est limitée à $maxGarageCars voitures.')));
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

  Future<void> _filter() async {
    var selectedSort = _sortBy;
    var selectedGroup = _groupBy;
    final options = await showBlurredModalBottomSheet<({_CarSortFilters sortBy, _CarGroupFilters? groupBy})>(
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
                  DropdownButtonFormField<_CarSortFilters>(
                    initialValue: selectedSort,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: _CarSortFilters.ownership, child: Text('Statut (possédée)')),
                      DropdownMenuItem(value: _CarSortFilters.name, child: Text('Nom')),
                      DropdownMenuItem(value: _CarSortFilters.brand, child: Text('Marque')),
                      DropdownMenuItem(value: _CarSortFilters.category, child: Text('Catégorie')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedSort = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SectionTitle('GROUPÉ PAR :'),
                  DropdownButtonFormField<_CarGroupFilters?>(
                    initialValue: selectedGroup,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Aucun')),
                      DropdownMenuItem(value: _CarGroupFilters.ownership, child: Text('Statut (possédée)')),
                      DropdownMenuItem(value: _CarGroupFilters.brand, child: Text('Marque')),
                      DropdownMenuItem(value: _CarGroupFilters.category, child: Text('Catégorie')),
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
      _CarSortFilters.ownership =>
        first.possedee == second.possedee
            ? 0
            : first.possedee
            ? -1
            : 1,
      _CarSortFilters.name => first.nom.toLowerCase().compareTo(second.nom.toLowerCase()),
      _CarSortFilters.brand => first.marque.toLowerCase().compareTo(second.marque.toLowerCase()),
      _CarSortFilters.category => _categoryName(first).toLowerCase().compareTo(_categoryName(second).toLowerCase()),
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
        _CarGroupFilters.ownership => car.possedee ? 'Possédées' : 'Non possédées',
        _CarGroupFilters.brand => car.marque,
        _CarGroupFilters.category => _categoryName(car),
      };
      groupedCars.putIfAbsent(groupName, () => []).add(car);
    }

    final groupNames = groupedCars.keys.toList();
    groupNames.sort((first, second) {
      if (_groupBy == _CarGroupFilters.ownership) {
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

  Future<bool> _updateCar(Car updatedCar) async {
    if (_savingCarIds.contains(updatedCar.id)) return false;
    final index = _cars.indexWhere((car) => car.id == updatedCar.id);
    if (index == -1) return false;

    final updatedCars = [..._cars];
    updatedCars[index] = updatedCar;
    setState(() => _savingCarIds.add(updatedCar.id));

    try {
      await _storage.saveCars(updatedCars);
      if (!mounted) return false;
      setState(() => _cars = updatedCars);
      return true;
    } catch (error) {
      if (mounted) _showSaveError(error);
      return false;
    } finally {
      if (mounted) setState(() => _savingCarIds.remove(updatedCar.id));
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      garagePageRoute<void>(
        SearchCarPage(
          existingCarIds: _cars.map((car) => car.id).toSet(),
          garageCapacity: maxGarageCars,
          onAddCar: _addCar,
          onRemoveCar: _removeCar,
          toggleOwnership: _toggleOwnership,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(garagePageRoute<void>(SettingsPage(garageCapacity: maxGarageCars)));
    if (mounted) await _loadCars();
  }

  Future<void> _openDetails(Car car) async {
    final sortedCars = _getDisplayedCars();
    final initialIndex = sortedCars.indexWhere((item) => item.id == car.id);
    if (initialIndex == -1) return;

    await Navigator.of(context).push<void>(
      garagePageRoute<void>(
        CarDetailPage(
          existingCarIds: _cars.map((car) => car.id).toSet(),
          cars: sortedCars,
          initialIndex: initialIndex,
          onPossessionChanged: _toggleOwnership,
          onRemove: _removeCar,
          onEdit: _updateCar,
        ),
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

  // -------------------------------------------------------------------------------------------------
  // | WIDGETS

  Widget buildEmptyGarage() => Container(
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
        return GarageCarCard(
          car: car,
          isSaving: _savingCarIds.contains(car.id),
          onTap: () => _openDetails(car),
          onLongPress: () => _showCarActions(car),
          onPossessionChanged: (value) => _toggleOwnership(car.id, value),
        );
      },
    );
  }

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

  // -------------------------------------------------------------------------------------------------
  // | BUILD

  @override
  Widget build(BuildContext context) {
    final acquiredCount = _cars.where((car) => car.possedee).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _filter,
        backgroundColor: Color(0xff23212e),
        child: Icon(Icons.filter_alt_outlined, color: pink),
      ),
      appBar: AppBar(
        title: Row(
          spacing: 10,
          children: [
            SizedBox(width: 35, height: 35, child: Image.asset("assets/images/garage.webp")),
            Text(
              'Leonida dream garage'.toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [IconButton(tooltip: 'Paramètres', onPressed: _openSettings, icon: const Icon(Icons.settings_outlined))],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? DefaultErrorWidget(message: _loadError!, onRetry: _loadCars)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  GradientButton(onPressed: _openSearch, icon: Icons.search, label: 'Rechercher une voiture', height: 40),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 8,
                    children: [
                      Tag(textSize: 12, label: '${_cars.length} / $maxGarageCars ${_cars.length == 1 ? 'voiture' : 'voitures'}'),
                      Tag(textSize: 12, label: '$acquiredCount possédée${acquiredCount == 1 ? '' : 's'}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_cars.isEmpty) buildEmptyGarage() else ..._buildCarSections(),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  // -------------------------------------------------------------------------------------------------
}
