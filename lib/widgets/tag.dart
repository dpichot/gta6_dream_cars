import 'package:material_ui/material_ui.dart';

class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.color, this.textColor, this.textSize = 8});

  final String label;
  final Color? color;
  final Color? textColor;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? const Color.fromARGB(98, 12, 13, 27), borderRadius: BorderRadius.circular(0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w800, letterSpacing: .5, color: textColor ?? Colors.white),
        ),
      ),
    );
  }
}
