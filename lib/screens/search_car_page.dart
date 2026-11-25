import 'package:gta6_dream_cars/main.dart';
import 'package:material_ui/material_ui.dart';

import '../data/car_catalog.dart';
import '../widgets/car_image.dart';
import '../widgets/gradient_button.dart';

class SearchCarPage extends StatefulWidget {
  const SearchCarPage({super.key, required this.existingCarIds});

  final Set<String> existingCarIds;

  @override
  State<SearchCarPage> createState() => _SearchCarPageState();
}

class _SearchCarPageState extends State<SearchCarPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final results = carCatalog.where((car) {
      return [car.nom, car.marque, car.categorie, car.categorie, car.modeleBase]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('RECHERCHER')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              autofocus: true,
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
                    child: Text(
                      'Aucune voiture trouvée.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final car = results[index];
                      final alreadyAdded = widget.existingCarIds.contains(
                        car.id,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(98, 12, 13, 27),
                        ),

                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: SizedBox(
                                  width: 104,
                                  height: 68 + 8,
                                  child: CarImage(car: car, thumbnail: true),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white.withValues(
                                                  alpha: .5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        car.nom.toUpperCase(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
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
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => Navigator.pop(context, car),
                                child: alreadyAdded
                                    ? const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      )
                                    : Icon(
                                        Icons.add_circle_outline_outlined,
                                        color: Colors.white,
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
