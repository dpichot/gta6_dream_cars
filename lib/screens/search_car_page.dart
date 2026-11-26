import 'package:gta6_dream_cars/main.dart';
import 'package:material_ui/material_ui.dart';

import '../data/car_catalog.dart';
import '../models/car.dart';
import '../widgets/car_image.dart';

class SearchCarPage extends StatefulWidget {
  const SearchCarPage({super.key, required this.existingCarIds, required this.garageCapacity, required this.onAddCar, required this.onRemoveCar});

  final Set<String> existingCarIds;
  final int garageCapacity;
  final Future<bool> Function(Car) onAddCar;
  final Future<bool> Function(String) onRemoveCar;

  @override
  State<SearchCarPage> createState() => _SearchCarPageState();
}

class _SearchCarPageState extends State<SearchCarPage> {
  late final Set<String> _existingCarIds = {...widget.existingCarIds};
  final Set<String> _updatingCarIds = {};
  String _query = '';

  bool get _isGarageFull => _existingCarIds.length >= widget.garageCapacity;

  Future<void> _toggleCar(Car car) async {
    if (_updatingCarIds.isNotEmpty) return;

    final alreadyAdded = _existingCarIds.contains(car.id);
    if (!alreadyAdded && _isGarageFull) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La liste est limitée à ${widget.garageCapacity} voitures.')));
      return;
    }

    setState(() => _updatingCarIds.add(car.id));
    try {
      final updated = alreadyAdded ? await widget.onRemoveCar(car.id) : await widget.onAddCar(car);
      if (!mounted || !updated) return;

      setState(() {
        if (alreadyAdded) {
          _existingCarIds.remove(car.id);
        } else {
          _existingCarIds.add(car.id);
        }
      });
    } finally {
      if (mounted) setState(() => _updatingCarIds.remove(car.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final results = carCatalog.where((car) {
      return [
        car.nom,
        car.marque,
        car.categorie,
        car.categorie,
        car.modeleBase,
      ].whereType<String>().any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('RECHERCHER')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final car = results[index];
                      final alreadyAdded = _existingCarIds.contains(car.id);
                      final isUpdating = _updatingCarIds.contains(car.id);
                      final isUpdatingAnyCar = _updatingCarIds.isNotEmpty;
                      return Container(
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
                                      if (car.categorie != null) ...[
                                        const SizedBox(height: 4),
                                        ClassTag(
                                          textSize: 10,
                                          label: car.categorie!.toUpperCase(),
                                          // style: const TextStyle(
                                          //   color: Color(0xFF53E0D0),
                                          //   fontSize: 10,
                                          //   fontWeight: FontWeight.w800,
                                          //   letterSpacing: 1,
                                          // ),
                                        ),
                                      ],
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
