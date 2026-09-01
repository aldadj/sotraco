import 'package:flutter/material.dart';
import '../../models/bus.dart';
import '../../models/ligne.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';

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
  final LocationService _locationService = LocationService();

  Future<void> _chargerDonnees() async {
    try {
      final responses = await Future.wait([ApiService.get('/buses'), ApiService.get('/lignes')]);
      final allBuses = (responses[0] as List)
        .map((item) => Bus.fromJson(Map<String, dynamic>.from(item)))
        .where((bus) => bus.statut == 'actif')
        .toList();
      final lignes = (responses[1] as List).map((item) => Ligne.fromJson(Map<String, dynamic>.from(item))).toList();
      if (!mounted) return;
      setState(() {
        _buses = allBuses;
        _lignes = lignes;
        _chargement = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _erreur = error.message; _chargement = false; });
    } catch (error) {
      if (mounted) setState(() { _erreur = error.toString(); _chargement = false; });
    }
  }

 Future<void> _demarrer() async {
  if (_busId == null || _ligneId == null) {
    setState(() {
      _erreur = 'Choisissez un bus et une ligne.';
    });
    return;
  }

  setState(() {
    _envoi = true;
    _erreur = null;
  });

  bool trajetCree = false;

  try {
    // ============================================================
    // 1. CRÉER LE TRAJET
    // ============================================================

    await ApiService.post(
      '/chauffeur/trajet/demarrer',
      {
        'bus_id': _busId,
        'ligne_id': _ligneId,
        'sens': _sens,
      },
    );

    trajetCree = true;

    // ============================================================
    // 2. ACTIVER LE GPS
    // ============================================================

    final partageDemarre =
        await _locationService.demarrerPartage(
      onErreur: (erreur) {
        if (mounted) {
          setState(() {
            _erreur = erreur;
          });
        }
      },
    );

    // ============================================================
    // 3. SI LE GPS ÉCHOUE
    //    ON ANNULE LE TRAJET CRÉÉ
    // ============================================================

    if (!partageDemarre) {
      if (trajetCree) {
        try {
          await ApiService.post(
            '/chauffeur/trajet/annuler',
            {},
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _erreur =
              'Le GPS n’a pas pu être activé. '
              'Le trajet a été annulé. '
              'Activez la localisation puis réessayez.';
        });
      }

      return;
    }

    // ============================================================
    // 4. TOUT EST OK
    // ============================================================

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  } on ApiException catch (error) {
    if (mounted) {
      setState(() {
        _erreur = error.message;
      });
    }
  } catch (error) {
    if (mounted) {
      setState(() {
        _erreur = error.toString();
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _envoi = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: const Text('Préparer le trajet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       const Text(
                          'Préparer ton trajet',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                            'Sélectionne le bus que tu conduis, la ligne et le sens du trajet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 22),
                        if (_buses.isEmpty)
                          const _MessageInfo(message: "Aucun bus disponible pour le moment. Un autre chauffeur circule peut-être déjà sur tous les bus actifs, ou demande à un administrateur d'en ajouter.")
                        else
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Bus disponible', prefixIcon: Icon(Icons.directions_bus_filled_rounded)),
                                  items: _buses.map((bus) => DropdownMenuItem<int>(value: bus.id, child: Text('${bus.numero} - ${bus.immatriculation}', overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (value) => setState(() => _busId = value),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Ligne', prefixIcon: Icon(Icons.alt_route_rounded)),
                                  items: _lignes.map((ligne) => DropdownMenuItem<int>(value: ligne.id, child: Text('${ligne.code} - ${ligne.nom}', overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (value) => setState(() => _ligneId = value),
                                ),
                                const SizedBox(height: 18),
                                const Text('Sens du trajet', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: _SensOption(label: 'Aller', icon: Icons.north_east_rounded, selected: _sens == 'aller', onTap: () => setState(() => _sens = 'aller'))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _SensOption(label: 'Retour', icon: Icons.south_west_rounded, selected: _sens == 'retour', onTap: () => setState(() => _sens = 'retour'))),
                                ]),
                              ],
                            ),
                          ),
                        if (_erreur != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                            child: Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                        if (_buses.isNotEmpty) ...[
                          const SizedBox(height: 26),
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
        ],
      ),
    );
  }
}

class _SensOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SensOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.heroGradient : null,
          color: selected ? null : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
        ]),
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
      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.textPrimary, height: 1.4))),
      ]),
    );
  }
}
