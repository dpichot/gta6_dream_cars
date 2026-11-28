import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:gta6_dream_cars/models/car.dart';
import 'package:gta6_dream_cars/widgets/car_image.dart';
import 'package:gta6_dream_cars/widgets/gradient_button.dart';
import 'package:gta6_dream_cars/widgets/section_title.dart';
import 'package:material_ui/material_ui.dart';

class EditCarPage extends StatefulWidget {
  const EditCarPage({super.key, required this.car});

  final Car car;

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.car.nom);
  late final _brandController = TextEditingController(text: widget.car.marque);
  late final _categoryController = TextEditingController(text: widget.car.categorie);
  late final _accessController = TextEditingController(text: widget.car.access);
  late final _trackerController = TextEditingController(text: widget.car.tracker);
  late final _styleController = TextEditingController(text: widget.car.style);
  late final _seatsController = TextEditingController(text: widget.car.nombrePlaces?.toString());
  late final _baseModelController = TextEditingController(text: widget.car.modeleBase);
  late final _dlcController = TextEditingController(text: widget.car.dlc);
  late final _roadRankController = TextEditingController(text: widget.car.classementRoute?.toString());
  late final _offRoadRankController = TextEditingController(text: widget.car.classementTerre?.toString());
  late final _speedController = TextEditingController(text: widget.car.stats?.vitesse?.toString());
  late final _accelerationController = TextEditingController(text: widget.car.stats?.acceleration?.toString());
  late final _asphaltController = TextEditingController(text: widget.car.stats?.adherenceAsphalte?.toString());
  late final _dirtController = TextEditingController(text: widget.car.stats?.adherenceTerre?.toString());
  late final _durabilityController = TextEditingController(text: widget.car.stats?.robustesse?.toString());
  late String _security = widget.car.securite == null
      ? 'unknown'
      : widget.car.securite!
      ? 'yes'
      : 'no';
  late bool _unique = widget.car.unique;
  late String? _imagePath = widget.car.imagePath;
  bool _isPickingImage = false;

  List<TextEditingController> get _controllers => [
    _nameController,
    _brandController,
    _categoryController,
    _accessController,
    _trackerController,
    _styleController,
    _seatsController,
    _baseModelController,
    _dlcController,
    _roadRankController,
    _offRoadRankController,
    _speedController,
    _accelerationController,
    _asphaltController,
    _dirtController,
    _durabilityController,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateInteger(String? value, {required int minimum, required int maximum}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    if (number == null || number < minimum || number > maximum) {
      return 'Saisis un nombre entre $minimum et $maximum.';
    }
    return null;
  }

  String? _validateRating(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || number < 0.1 || number > 10) {
      return 'Saisis une note entre 0,1 et 10.';
    }
    return null;
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final selectedFile = await FilePicker.pickFile(dialogTitle: 'Choisir une image', type: FileType.image);
      if (selectedFile == null) return;
      final imagePath = selectedFile.path;
      if (imagePath == null) {
        throw StateError('Le chemin de cette image est indisponible.');
      }
      if (mounted) setState(() => _imagePath = imagePath);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de sélectionner l’image : $error')));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool requiredField = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        filled: false,
        fillColor: const Color.fromARGB(98, 12, 13, 27),
        border: const UnderlineInputBorder(
          borderRadius: BorderRadius.zero,
          // borderSide: BorderSide(color: Color.fromARGB(200, 12, 13, 27)),
        ),
      ),
      validator: validator ?? (requiredField ? (value) => value == null || value.trim().isEmpty ? 'Ce champ est obligatoire.' : null : null),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    String? optionalText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    int? optionalInteger(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : int.parse(value);
    }

    double? optionalRating(TextEditingController controller) {
      final value = controller.text.trim().replaceAll(',', '.');
      return value.isEmpty ? null : double.parse(value);
    }

    final stats = CarStats(
      vitesse: optionalRating(_speedController),
      acceleration: optionalRating(_accelerationController),
      adherenceAsphalte: optionalRating(_asphaltController),
      adherenceTerre: optionalRating(_dirtController),
      robustesse: optionalRating(_durabilityController),
    );
    final updatedCar = Car(
      id: widget.car.id,
      nom: _nameController.text.trim(),
      marque: _brandController.text.trim(),
      possedee: widget.car.possedee,
      categorie: optionalText(_categoryController),
      securite: _security == 'unknown' ? null : _security == 'yes',
      access: optionalText(_accessController),
      tracker: optionalText(_trackerController),
      style: optionalText(_styleController),
      nombrePlaces: optionalInteger(_seatsController),
      classementRoute: optionalInteger(_roadRankController),
      classementTerre: optionalInteger(_offRoadRankController),
      modeleBase: optionalText(_baseModelController),
      stats: [stats.vitesse, stats.acceleration, stats.adherenceAsphalte, stats.adherenceTerre, stats.robustesse].every((value) => value == null)
          ? null
          : stats,
      unique: _unique,
      dlc: optionalText(_dlcController),
      detailsEdited: true,
      imagePath: _imagePath,
    );
    Navigator.of(context).pop(updatedCar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('MODIFIER LA VOITURE')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SectionTitle('IMAGE'),
              ClipRRect(
                child: AspectRatio(
                  aspectRatio: 1.65,
                  child: Material(
                    color: const Color(0xFF292C38),
                    child: InkWell(
                      onTap: _isPickingImage ? null : _pickImage,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_imagePath == null)
                            CarImage(car: widget.car)
                          else
                            Image.file(
                              File(_imagePath!),
                              key: ValueKey(_imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => CarImage(car: widget.car),
                            ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: const Color(0x99000000),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isPickingImage)
                                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  else
                                    const Icon(Icons.photo_camera_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_isPickingImage ? 'Chargement…' : 'Toucher pour remplacer l’image'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const SectionTitle('INFORMATIONS'),
              Container(
                color: const Color.fromARGB(98, 12, 13, 27),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Véhicule remarquable'),
                      value: _unique,
                      onChanged: (value) => setState(() => _unique = value),
                    ),
                    // const SizedBox(height: 12),
                    _textField('Nom', _nameController, requiredField: true),
                    const SizedBox(height: 12),
                    _textField('Marque', _brandController, requiredField: true),
                    const SizedBox(height: 12),
                    _textField('Catégorie', _categoryController),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _security,
                      decoration: const InputDecoration(
                        labelText: 'Sécurité',
                        border: UnderlineInputBorder(),
                        filled: false,
                        fillColor: Color.fromARGB(98, 12, 13, 27),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('Non renseignée')),
                        DropdownMenuItem(value: 'yes', child: Text('Oui')),
                        DropdownMenuItem(value: 'no', child: Text('Non')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _security = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _textField('Accès', _accessController),
                    const SizedBox(height: 12),
                    _textField('Traceur', _trackerController),
                    const SizedBox(height: 12),
                    _textField('Style', _styleController),
                    const SizedBox(height: 12),
                    _textField(
                      'Nombre de places',
                      _seatsController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateInteger(value, minimum: 1, maximum: 99),
                    ),
                    const SizedBox(height: 12),
                    _textField('Modèle de base', _baseModelController),
                    const SizedBox(height: 12),
                    _textField('DLC', _dlcController),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const SectionTitle('CLASSEMENTS'),
              Container(
                color: const Color.fromARGB(98, 12, 13, 27),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    _textField(
                      'Classement route (1 à 999)',
                      _roadRankController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateInteger(value, minimum: 1, maximum: 999),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Classement tout-terrain (1 à 999)',
                      _offRoadRankController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateInteger(value, minimum: 1, maximum: 999),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const SectionTitle('PERFORMANCES (0,1 À 10)'),
              Container(
                color: const Color.fromARGB(98, 12, 13, 27),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    _textField(
                      'Vitesse',
                      _speedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateRating,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Accélération',
                      _accelerationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateRating,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Adhérence asphalte',
                      _asphaltController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateRating,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Adhérence terre',
                      _dirtController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateRating,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Robustesse',
                      _durabilityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateRating,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: GradientButton(label: 'ENREGISTRER', icon: Icons.check, onPressed: _save),
      ),
    );
  }
}
