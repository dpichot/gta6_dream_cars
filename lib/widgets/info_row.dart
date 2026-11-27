import 'package:material_ui/material_ui.dart';

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {this.isLast = false, super.key});

  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 13, 16, isLast ? 13 : 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label.toUpperCase())),
              const SizedBox(width: 12),
              if ((label == "Sécurité" || label == "Accès" || label == "Traceur") && value != null)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Icon(
                      label == "Sécurité"
                          ? Icons.shield
                          : label == "Traceur"
                          ? Icons.gps_fixed
                          : Icons.key,
                      size: 12,
                      color: label == "Sécurité"
                          ? (value == "true" ? Colors.red : Colors.grey)
                          : label == "Traceur"
                          ? ((value?.contains("Advanced") ?? false) ? Colors.red : Colors.orange)
                          : ((value?.contains("Key cloner") ?? false) ? Colors.red : Colors.white),
                    ),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    (value ?? 'Non renseigné').toUpperCase(),
                    textAlign: TextAlign.end,
                    style: TextStyle(color: value == null ? Colors.white.withValues(alpha: .5) : Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Divider(height: 1, color: Color(0xFF292C38)),
            ),
        ],
      ),
    );
  }
}
