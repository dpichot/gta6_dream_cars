import 'package:material_ui/material_ui.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final borderRadius = BorderRadius.circular(compact ? 12 : 16);
    final colors = enabled
        ? const [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(158, 173, 173, 173),
          ]
        : const [Color(0xFF454753), Color(0xFF30323D)];

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            // borderRadius: borderRadius,
            boxShadow: enabled && !compact
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF4F9A).withValues(alpha: .2),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: compact ? 78 : 0,
                minHeight: height,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 20,
                  vertical: compact ? 8 : 14,
                ),
                child: Row(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: compact ? 16 : 20, color: Colors.black),
                      SizedBox(width: compact ? 6 : 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: compact ? 12 : 17,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
