import 'package:gta6_dream_cars/widgets/garage_background.dart';
import 'package:material_ui/material_ui.dart';

PageRouteBuilder<T> garagePageRoute<T>(Widget page) {
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
