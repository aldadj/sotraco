import 'package:flutter/material.dart';
import '../../models/bus.dart';
import '../../models/ligne.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  List<Bus> _buses = [];
  List<Ligne> _lignes = [];
  int? _busId;
  int? _ligneId;
  String _sens = 'aller';
  bool _chargement = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final responses = await Future.wait([
        ApiService.get('/buses'),
        ApiService.get('/lignes'),
      ]);
      final allBuses = (responses[0] as List)
          .map((item) => Bus.fromJson(Map<String, dynamic>.from(item)))
          .where((bus) => bus.statut == 'actif' && bus.sens == null)
          .toList();
      final lignes = (responses[1] as List)
          .map((item) => Ligne.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _buses = allBuses;
        _lignes = lignes;
        _chargement = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _erreur = error.message;
          _chargement = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _erreur = error.toString();
          _chargement = false;
        });
      }
    }
  }

  Future<void> _demarrer() async {
    if (_busId == null || _ligneId == null) {
      setState(() => _erreur = 'Choisissez un bus et une ligne.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ApiService.post('/chauffeur/trajet/demarrer', {
        'bus_id': _busId,
        'ligne_id': _ligneId,
        'sens': _sens,
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _erreur = error.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préparer le trajet')),
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avant de partager votre position', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Sélectionnez le bus, la ligne et le sens du trajet.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    if (_buses.isEmpty)
                      const _MessageInfo(message: 'Aucun bus ne vous est attribué. Demandez à un administrateur de vous affecter un bus.')
                    else ...[
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Bus', prefixIcon: Icon(Icons.directions_bus_filled_rounded)),
                        items: _buses.map((bus) => DropdownMenuItem<int>(value: bus.id, child: Text('${bus.numero} - ${bus.immatriculation}'))).toList(),
                        onChanged: (value) => setState(() => _busId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Ligne', prefixIcon: Icon(Icons.alt_route_rounded)),
                        items: _lignes.map((ligne) => DropdownMenuItem<int>(value: ligne.id, child: Text('${ligne.code} - ${ligne.nom}'))).toList(),
                        onChanged: (value) => setState(() => _ligneId = value),
                      ),
                      const SizedBox(height: 18),
                      const Text('Sens du trajet', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'aller', label: Text('Aller'), icon: Icon(Icons.arrow_forward_rounded)),
                          ButtonSegment(value: 'retour', label: Text('Retour'), icon: Icon(Icons.arrow_back_rounded)),
                        ],
                        selected: {_sens},
                        onSelectionChanged: (selection) => setState(() => _sens = selection.first),
                      ),
                    ],
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    if (_buses.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _envoi ? null : _demarrer,
                          icon: _envoi ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                          label: const Text('Démarrer le trajet'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _MessageInfo extends StatelessWidget {
  final String message;

  const _MessageInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}
