import 'package:material_ui/material_ui.dart';

class GarageBackground extends StatelessWidget {
  const GarageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 41, 47, 90), Color.fromARGB(255, 66, 38, 85), Color.fromARGB(255, 46, 21, 38)],
          stops: [0, .48, 1],
        ),
      ),
      child: child,
    );
  }
}
