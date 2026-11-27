import 'package:gta6_dream_cars/main.dart';
import 'package:gta6_dream_cars/screens/car_detail_page.dart';
import 'package:gta6_dream_cars/utils/routeur.dart';
import 'package:gta6_dream_cars/widgets/tag.dart';
import 'package:material_ui/material_ui.dart';

import '../data/car_catalog.dart';
import '../models/car.dart';
import '../widgets/blurred_modal_bottom_sheet.dart';
import '../widgets/car_image.dart';
import '../widgets/gradient_button.dart';

typedef _SearchFilters = ({String? brand, String? category, bool? remarkable, bool? dlc, bool ascending});

class SearchCarPage extends StatefulWidget {
  const SearchCarPage({
    super.key,
    required this.existingCarIds,
    required this.garageCapacity,
    required this.onAddCar,
    required this.onRemoveCar,
    required this.toggleOwnership,
  });

  final Set<String> existingCarIds;
  final int garageCapacity;
  final Future<bool> Function(Car) onAddCar;
  final Future<bool> Function(String) onRemoveCar;
  final Future<bool> Function(String id, bool possedee) toggleOwnership;

  @override
  State<SearchCarPage> createState() => _SearchCarPageState();
}

class _SearchCarPageState extends State<SearchCarPage> {
  // -------------------------------------------------------------------------------------------------
  // | STATES

  late final Set<String> _existingCarIds = {...widget.existingCarIds};
  final Set<String> _updatingCarIds = {};
  String _query = '';
  String? _brandFilter;
  String? _categoryFilter;
  bool? _remarkableFilter;
  bool? _dlcFilter;
  bool _sortAscending = true;

  List<Car> results = [];

  // -------------------------------------------------------------------------------------------------
  // | GETTERS

  bool get _isGarageFull => _existingCarIds.length >= widget.garageCapacity;

  // -------------------------------------------------------------------------------------------------
  // | METHODS

  Future<bool> _toggleCar(Car car) async {
    if (_updatingCarIds.isNotEmpty) return false;

    final alreadyAdded = _existingCarIds.contains(car.id);
    if (!alreadyAdded && _isGarageFull) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La liste est limitée à ${widget.garageCapacity} voitures.')));
      return false;
    }

    setState(() => _updatingCarIds.add(car.id));
    try {
      final updated = alreadyAdded ? await widget.onRemoveCar(car.id) : await widget.onAddCar(car);
      if (!mounted || !updated) return false;

      setState(() {
        if (alreadyAdded) {
          _existingCarIds.remove(car.id);
        } else {
          _existingCarIds.add(car.id);
        }
      });
      return true;
    } finally {
      if (mounted) setState(() => _updatingCarIds.remove(car.id));
    }
  }

  String _categoryName(Car car) {
    final category = car.categorie?.trim();
    return category == null || category.isEmpty ? 'Non catégorisée' : category;
  }

  Future<void> _showFilters() async {
    var selectedBrand = _brandFilter ?? '';
    var selectedCategory = _categoryFilter ?? '';
    var selectedRemarkable = switch (_remarkableFilter) {
      true => 'remarkable',
      false => 'not_remarkable',
      null => 'all',
    };
    var selectedDlc = switch (_dlcFilter) {
      true => 'dlc',
      false => 'not_dlc',
      null => 'all',
    };
    var selectedAscending = _sortAscending;
    final brands = carCatalog.map((car) => car.marque).toSet().toList()..sort((first, second) => first.toLowerCase().compareTo(second.toLowerCase()));
    final categories = carCatalog.map(_categoryName).toSet().toList()..sort((first, second) => first.toLowerCase().compareTo(second.toLowerCase()));

    final filters = await showBlurredModalBottomSheet<_SearchFilters>(
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
                  const Text('MARQUE :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBrand,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Toutes les marques')),
                      for (final brand in brands) DropdownMenuItem(value: brand, child: Text(brand)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedBrand = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('CATÉGORIE :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Toutes les catégories')),
                      for (final category in categories) DropdownMenuItem(value: category, child: Text(category)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('REMARQUABLE :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRemarkable,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Toutes les voitures')),
                      DropdownMenuItem(value: 'remarkable', child: Text('Remarquables uniquement')),
                      DropdownMenuItem(value: 'not_remarkable', child: Text('Non remarquables uniquement')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedRemarkable = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('DLC :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDlc,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Toutes les voitures')),
                      DropdownMenuItem(value: 'dlc', child: Text('DLC uniquement')),
                      DropdownMenuItem(value: 'not_dlc', child: Text('Non DLC uniquement')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedDlc = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('ORDRE ALPHABÉTIQUE :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  DropdownButtonFormField<bool>(
                    initialValue: selectedAscending,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF191526),
                    decoration: filterDropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Croissant (A-Z)')),
                      DropdownMenuItem(value: false, child: Text('Décroissant (Z-A)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedAscending = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    onPressed: () => Navigator.pop(sheetContext, (
                      brand: selectedBrand.isEmpty ? null : selectedBrand,
                      category: selectedCategory.isEmpty ? null : selectedCategory,
                      remarkable: switch (selectedRemarkable) {
                        'remarkable' => true,
                        'not_remarkable' => false,
                        _ => null,
                      },
                      dlc: switch (selectedDlc) {
                        'dlc' => true,
                        'not_dlc' => false,
                        _ => null,
                      },
                      ascending: selectedAscending,
                    )),
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

    if (filters == null || !mounted) return;
    setState(() {
      _brandFilter = filters.brand;
      _categoryFilter = filters.category;
      _remarkableFilter = filters.remarkable;
      _dlcFilter = filters.dlc;
      _sortAscending = filters.ascending;
    });
  }

  int _compareCars(Car first, Car second) {
    final nameComparison = first.nom.toLowerCase().compareTo(second.nom.toLowerCase());
    final comparison = nameComparison != 0 ? nameComparison : first.id.compareTo(second.id);
    return _sortAscending ? comparison : -comparison;
  }

  Future<void> _openDetails(Car car) async {
    final initialIndex = results.indexWhere((item) => item.id == car.id);
    if (initialIndex == -1) return;

    await Navigator.of(context).push<void>(
      garagePageRoute<void>(
        CarDetailPage(
          cars: results,
          initialIndex: initialIndex,
          onPossessionChanged: widget.toggleOwnership,
          onToggle: _toggleCar,
          existingCarIds: _existingCarIds,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------------------------------
  // | BUILD

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    results = carCatalog.where((car) {
      final matchesQuery = [
        car.nom,
        car.marque,
        _categoryName(car),
        car.modeleBase,
      ].whereType<String>().any((value) => value.toLowerCase().contains(normalizedQuery));
      final matchesBrand = _brandFilter == null || car.marque == _brandFilter;
      final matchesCategory = _categoryFilter == null || _categoryName(car) == _categoryFilter;
      final matchesRemarkable = _remarkableFilter == null || car.unique == _remarkableFilter;
      final hasDlc = car.dlc?.trim().isNotEmpty ?? false;
      final matchesDlc = _dlcFilter == null || hasDlc == _dlcFilter;

      return matchesQuery && matchesBrand && matchesCategory && matchesRemarkable && matchesDlc;
    }).toList()..sort(_compareCars);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilters,
        backgroundColor: const Color(0xff23212e),
        child: Icon(Icons.filter_alt_outlined, color: pink),
      ),
      appBar: AppBar(
        title: const Text('RECHERCHER'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Tag(textSize: 12, label: "${results.length.toString()} voitures"),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 16),
            child: TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Nom du véhicule ou marque',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                // fillColor: const Color(0xFF171922),
                fillColor: const Color.fromARGB(98, 12, 13, 27),

                border: OutlineInputBorder(
                  // borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text('Aucune voiture trouvée.', style: TextStyle(color: Colors.white.withValues(alpha: .7))),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: results.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == results.length) {
                        return SizedBox(height: 80);
                      }
                      final car = results[index];
                      final alreadyAdded = _existingCarIds.contains(car.id);
                      final isUpdating = _updatingCarIds.contains(car.id);
                      final isUpdatingAnyCar = _updatingCarIds.isNotEmpty;
                      return InkWell(
                        onTap: () => _openDetails(car),
                        child: Container(
                          decoration: BoxDecoration(color: const Color.fromARGB(98, 12, 13, 27)),

                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: SizedBox(width: 104, height: 75, child: CarImage(car: car, thumbnail: true)),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            CarBrandLogo(car: car, size: 15),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                car.marque.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: .5)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          car.nom.toUpperCase(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        Row(
                                          children: [
                                            if (car.categorie != null) ...[
                                              const SizedBox(height: 4),
                                              Tag(textSize: 10, label: car.categorie!.toUpperCase()),
                                            ],
                                            if (car.unique) ...[
                                              const SizedBox(height: 4),
                                              Tag(textSize: 10, label: "★", color: Color.fromARGB(153, 255, 191, 0)),
                                            ],
                                            if (car.dlc != null) ...[
                                              const SizedBox(height: 4),
                                              Tag(textSize: 10, label: "★", color: Color.fromARGB(153, 189, 0, 0)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  key: ValueKey('toggle-car-${car.id}'),
                                  onTap: isUpdatingAnyCar ? null : () => _toggleCar(car),
                                  child: Padding(
                                    padding: EdgeInsetsGeometry.all(10),
                                    child: isUpdating
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2)),
                                          )
                                        : alreadyAdded
                                        ? const Icon(Icons.remove_circle_outline, color: Colors.red)
                                        : Icon(
                                            Icons.add_circle_outline_outlined,
                                            color: _isGarageFull ? Colors.white.withValues(alpha: .35) : Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------------------------------
}
