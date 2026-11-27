import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/car_storage.dart';
import '../services/garage_backup.dart';
import '../widgets/section_title.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.garageCapacity});

  final int garageCapacity;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final CarStorage _storage = CarStorage();
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _isBusy = false;

  Future<void> _runAction(String errorMessage, Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$errorMessage : $error')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportGarage() async {
    final cars = await _storage.loadCars();
    final savedFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter le garage',
      fileName: 'dream_garage_backup.json',
      mimeType: 'application/json',
      bytes: GarageBackup.encode(cars),
    );
    if (savedFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde du garage exportée.')));
    }
  }

  Future<void> _importGarage() async {
    final selectedFile = await FilePicker.pickFile(dialogTitle: 'Importer une sauvegarde', type: FileType.custom, allowedExtensions: ['json']);
    if (selectedFile == null) return;

    final importedCars = GarageBackup.decode(await selectedFile.readAsBytes(), maxCars: widget.garageCapacity);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remplacer le garage ?'),
        content: Text('Le garage actuel sera remplacé par ${importedCars.length} voiture${importedCars.length == 1 ? '' : 's'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Importer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _storage.saveCars(importedCars);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Garage importé avec succès.')));
    }
  }

  Future<void> _confirmAndClearGarage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vider le garage ?'),
        content: const Text('Toutes les voitures du garage seront supprimées. Les autres données de l’application seront conservées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Vider le garage')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runAction('Impossible de vider le garage', () async {
      await _storage.clearCars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Garage vidé.')));
      }
    });
  }

  void _showLicenses() {
    showLicensePage(context: context, applicationName: 'Leonida Dream Garage');
  }

  Widget _settingsPanel(List<Widget> children) {
    return Material(
      color: const Color.fromARGB(98, 12, 13, 27),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('PARAMÈTRES')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const SectionTitle('DONNÉES DU GARAGE'),
          _settingsPanel([
            ListTile(
              leading: _isBusy ? const _BusyIndicator() : const Icon(Icons.download_outlined),
              title: const Text('Exporter'),
              subtitle: const Text('Enregistre une sauvegarde de votre garage'),
              onTap: _isBusy ? null : () => _runAction('Impossible d’exporter le garage', _exportGarage),
            ),
            const Divider(height: 1, color: Color(0xFF292C38)),
            ListTile(
              leading: _isBusy ? const _BusyIndicator() : const Icon(Icons.upload_outlined),
              title: const Text('Importer'),
              subtitle: const Text('Remplace le contenu actuel du garage'),
              onTap: _isBusy ? null : () => _runAction('Impossible d’importer la sauvegarde', _importGarage),
            ),
            const Divider(height: 1, color: Color(0xFF292C38)),
            ListTile(
              leading: _isBusy ? const _BusyIndicator() : const Icon(Icons.delete_outline),
              title: const Text('Vider le garage'),
              subtitle: const Text('Supprimer les voitures enregistrées'),
              onTap: _isBusy ? null : _confirmAndClearGarage,
            ),
          ]),
          const SizedBox(height: 20),
          const SectionTitle('APPLICATION'),
          _settingsPanel([
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              subtitle: FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Impossible de lire la version : ${snapshot.error}');
                  if (!snapshot.hasData) return const Text('Chargement...');
                  final info = snapshot.data!;
                  return Text('${info.version}+${info.buildNumber}');
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFF292C38)),
            const ListTile(leading: Icon(Icons.flutter_dash), title: Text('Powered by Flutter')),
            const Divider(height: 1, color: Color(0xFF292C38)),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licences open source'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLicenses,
            ),
          ]),
        ],
      ),
    );
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
  }
}
