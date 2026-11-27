
import 'package:material_ui/material_ui.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({super.key, required this.routeRank, required this.terrainRank});

  final int? routeRank;
  final int? terrainRank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _RankingItem(label: 'Classement route', icon: Icons.route, value: routeRank),
        const SizedBox(width: 20),
        _RankingItem(label: 'Classement terre', icon: Icons.terrain, value: terrainRank),
      ],
    );
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({required this.label, required this.icon, required this.value});

  final String label;
  final IconData icon;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        label: '$label: ${value ?? 'non renseigné'}',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(value?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
