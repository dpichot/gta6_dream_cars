import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../models/car.dart';

class CarImage extends StatelessWidget {
  const CarImage({super.key, required this.car, this.thumbnail = false, this.fit = BoxFit.cover});

  final Car car;
  final bool thumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (car.imagePath != null) {
      return Image.file(
        File(car.imagePath!),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildAssetImage(_imageCandidates(car), 0),
      );
    }

    return _buildAssetImage(_imageCandidates(car), 0);
  }

  List<String> _imageCandidates(Car car) {
    final brand = _slugify(car.marque);
    final name = _slugify(car.nom);
    final year = _yearInName(car.nom);

    return {
      'assets/cars/${car.id}.jpg',
      'assets/cars/$brand-${car.id}.jpg',
      if (year != null) 'assets/cars/${car.id}-$year.jpg',
      'assets/cars/$name.jpg',
      if (year != null) 'assets/cars/$brand-${car.id}-$year.jpg',
      'assets/cars/$brand-$name.jpg',
      if (year != null) 'assets/cars/$name-$year.jpg',
    }.toList();
  }

  Widget _buildAssetImage(List<String> candidates, int index) {
    return Image.asset(
      candidates[index],
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (index + 1 < candidates.length) {
          return _buildAssetImage(candidates, index + 1);
        }

        return const ColoredBox(
          color: Color(0xFF292C38),
          child: Center(child: Icon(Icons.directions_car, color: Color(0xFFFF4F9A), size: 36)),
        );
      },
    );
  }

  String? _yearInName(String name) {
    return RegExp(r"(?:['’]\s*|\b(?:19|20))(\d{2})\b").firstMatch(name)?.group(1);
  }

  String _slugify(String value) {
    var slug = value.toLowerCase();
    const replacements = {
      'ä': 'a',
      'à': 'a',
      'â': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'æ': 'ae',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ø': 'o',
      'œ': 'oe',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'ß': 'ss',
    };
    for (final replacement in replacements.entries) {
      slug = slug.replaceAll(replacement.key, replacement.value);
    }

    return slug.replaceAll(RegExp(r"['’`´]"), '').replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class CarBrandLogo extends StatelessWidget {
  const CarBrandLogo({super.key, required this.car, this.size = 28});

  final Car car;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/manufacturers/${car.marque.toLowerCase()}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF292C38),
        child: Text(
          car.marque.substring(0, 1).toUpperCase(),
          style: TextStyle(color: const Color(0xFF53E0D0), fontSize: size * .48, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
