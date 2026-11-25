import 'package:gta6_dream_cars/main.dart';
import 'package:material_ui/material_ui.dart';

import '../models/car.dart';
import '../widgets/car_image.dart';
import '../widgets/gradient_button.dart';

class CarDetailPage extends StatefulWidget {
  const CarDetailPage({
    super.key,
    required this.car,
    required this.onPossessionChanged,
    required this.onRemove,
  });

  final Car car;
  final Future<bool> Function(bool) onPossessionChanged;
  final Future<bool> Function() onRemove;

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late Car _car = widget.car;
  bool _isSaving = false;

  Future<void> _confirmAndRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette voiture ?'),
        content: Text('« ${_car.nom} » sera retirée de ton garage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          GradientButton(
            label: 'Supprimer',
            compact: true,
            height: 40,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final removed = await widget.onRemove();
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (removed) Navigator.of(context).pop();
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePossession(bool value) async {
    setState(() => _isSaving = true);
    try {
      final saved = await widget.onPossessionChanged(value);
      if (!mounted) return;
      setState(() {
        if (saved) _car = _car.copyWith(possedee: value);
        _isSaving = false;
      });
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FICHE VÉHICULE'),
        actions: [
          IconButton(
            tooltip: 'Supprimer de la liste',
            onPressed: _isSaving ? null : _confirmAndRemove,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: AspectRatio(
                  aspectRatio: 1.65,
                  child: CarImage(car: _car),
                ),
              ),
              if (_car.categorie != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: ClassTag(
                    label: _car.categorie!.toUpperCase(),
                    textSize: 14,
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: CarBrandLogo(car: _car, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  _car.marque.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 25,
                    color: Color.fromARGB(255, 167, 167, 167),
                  ),
                ),
              ),
            ],
          ),
          Text(
            _car.nom.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color.fromARGB(98, 12, 13, 27),
            child: SwitchListTile(
              key: ValueKey('detail-ownership-${_car.id}'),
              title: Text('Possédée'.toUpperCase()),
              value: _car.possedee,
              onChanged: _isSaving ? null : _changePossession,
              activeThumbColor: const Color(0xFF53E0D0),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('CARACTÉRISTIQUES'),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(98, 12, 13, 27),
            ),
            child: Column(
              children: [
                _InfoRow('Sécurité', _car.securite),
                _InfoRow('Style', _car.style),
                _InfoRow('Nombre de places', _car.nombrePlaces?.toString()),
                _InfoRow('Modèle de base', _car.modeleBase, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('PERFORMANCES'),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(98, 12, 13, 27),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RankingRow(
                    routeRank: _car.classementRoute,
                    terrainRank: _car.classementTerre,
                  ),
                  SizedBox(height: 16),
                  _RatingRow('Vitesse', _car.stats?.vitesse),
                  _RatingRow('Accélération', _car.stats?.acceleration),
                  _RatingRow(
                    'Adhérence asphalte',
                    _car.stats?.adherenceAsphalte,
                  ),
                  _RatingRow('Adhérence terre', _car.stats?.adherenceTerre),
                  _RatingRow(
                    'Robustesse',
                    _car.stats?.robustesse,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.isLast = false});

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
              Flexible(
                child: Text(
                  (value ?? 'Non renseigné').toUpperCase(),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: value == null
                        ? Colors.white.withValues(alpha: .5)
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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

class _RatingRow extends StatelessWidget {
  const _RatingRow(this.label, this.value, {this.isLast = false});

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
                  style: TextStyle(
                    color: value == null
                        ? Colors.white.withValues(alpha: .5)
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
              child: Slider(
                value: value!.clamp(1.0, 10.0).toDouble(),
                min: 1,
                max: 10,
                onChanged: null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.routeRank,
    required this.terrainRank,
  });

  final int? routeRank;
  final int? terrainRank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _RankingItem(
          label: 'Classement route',
          icon: Icons.route,
          value: routeRank,
        ),
        const SizedBox(width: 20),
        _RankingItem(
          label: 'Classement terre',
          icon: Icons.terrain,
          value: terrainRank,
        ),
      ],
    );
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({
    required this.label,
    required this.icon,
    required this.value,
  });

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
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              value?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
