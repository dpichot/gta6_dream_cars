import 'package:gta6_dream_cars/widgets/gradient_button.dart';
import 'package:material_ui/material_ui.dart';

class DefaultErrorWidget extends StatelessWidget {
  const DefaultErrorWidget({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GradientButton(label: 'Réessayer', onPressed: onRetry, height: 44),
          ],
        ),
      ),
    );
  }
}
