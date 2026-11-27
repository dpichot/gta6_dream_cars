import 'package:gta6_dream_cars/main.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:gta6_dream_cars/widgets/car_image.dart';
import 'package:gta6_dream_cars/widgets/tag.dart';
import 'package:material_ui/material_ui.dart';

class GarageCarCard extends StatelessWidget {
  const GarageCarCard({
    super.key,
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
                      if (car.categorie != null) Positioned(top: 5, right: 5, child: Tag(label: car.categorie!)),
                      Positioned(top: 5, left: 5, child: CarBrandLogo(car: car, size: 18)),
                      if (car.unique)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Tag(label: "Remarquable", color: Color.fromARGB(153, 255, 191, 0)),
                        ),
                      if (car.dlc != null)
                        Positioned(
                          bottom: 5,
                          left: 5,
                          child: Tag(label: car.dlc!, color: Color.fromARGB(153, 189, 0, 0)),
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
