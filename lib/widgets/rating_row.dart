

import 'package:material_ui/material_ui.dart';

class RatingRow extends StatelessWidget {
  const RatingRow(this.label, this.value, {this.isLast = false, super.key});

  final String label;
  final double? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label.toUpperCase())),
              Container(
                color: const Color.fromARGB(255, 13, 14, 18),
                child: Text(
                  value == null ? 'Non renseigné' : value!.toStringAsFixed(1),
                  style: TextStyle(color: value == null ? Colors.white.withValues(alpha: .5) : Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 10,
                disabledActiveTrackColor: Colors.white,
                disabledInactiveTrackColor: const Color(0xFF292C38),
                disabledThumbColor: Colors.white,
                overlayColor: Colors.transparent,
                trackShape: RectangularSliderTrackShape(),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
                padding: const EdgeInsets.all(0),
              ),
              child: Slider(value: value!.clamp(1.0, 10.0).toDouble(), min: 1, max: 10, onChanged: null),
            ),
          ],
        ],
      ),
    );
  }
}
