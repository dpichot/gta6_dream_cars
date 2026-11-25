import 'package:material_ui/material_ui.dart';

import '../models/car.dart';

class CarImage extends StatelessWidget {
  const CarImage({
    super.key,
    required this.car,
    this.thumbnail = false,
    this.fit = BoxFit.cover,
  });

  final Car car;
  final bool thumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = thumbnail
        ? car.petiteImage ?? car.image
        : car.image ?? car.petiteImage;
    if (path == null) {
      return const ColoredBox(
        color: Color(0xFF292C38),
        child: Center(
          child: Icon(Icons.directions_car, color: Color(0xFFFF4F9A), size: 36),
        ),
      );
    }
    return Image.asset(path, fit: fit);
  }
}

class CarBrandLogo extends StatelessWidget {
  const CarBrandLogo({super.key, required this.car, this.size = 28});

  final Car car;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = car.logoMarque;
    if (logo != null) {
      return Image.asset(logo, width: size, height: size, fit: BoxFit.contain);
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF292C38),
      child: Text(
        car.marque.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF53E0D0),
          fontSize: size * .48,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
