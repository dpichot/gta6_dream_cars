import 'package:gta6_dream_cars/screens/garage_page.dart';
import 'package:material_ui/material_ui.dart';

import 'widgets/garage_background.dart';

const pink = Color.fromARGB(255, 255, 151, 196);
const turquoise = Color(0xFF22CBB5);

const maxGarageCars = 22;

final ValueNotifier<bool> editionMode = ValueNotifier(false);

void main() {
  runApp(const GarageApp());
}

class GarageApp extends StatelessWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leonida Dream Garage',
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
