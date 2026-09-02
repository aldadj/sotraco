import 'package:flutter/material.dart';

import '../../models/bus.dart';
import '../../models/ligne.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  final LocationService _locationService = LocationService();

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

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CHARGER LES BUS ET LES LIGNES
  // ==========================================================================

  Future<void> _chargerDonnees() async {
    try {
      final responses = await Future.wait([
        ApiService.get('/buses'),
        ApiService.get('/lignes'),
      ]);

      final busesResponse = responses[0];
      final lignesResponse = responses[1];

      final allBuses = (busesResponse as List)
          .map(
            (item) => Bus.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (bus) => bus.statut == 'actif',
          )
          .toList();

      final lignes = (lignesResponse as List)
          .map(
            (item) => Ligne.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _buses = allBuses;
        _lignes = lignes;
        _chargement = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _erreur = error.message;
        _chargement = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _erreur = 'Erreur lors du chargement : $error';
        _chargement = false;
      });
    }
  }

  // ==========================================================================
  // DÉMARRER LE TRAJET
  // ==========================================================================

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
    // 1. VÉRIFIER GPS
    // ============================================================

    debugPrint('========== DÉMARRAGE TRAJET ==========');
    debugPrint('🚌 Bus ID : $_busId');
    debugPrint('🛣️ Ligne ID : $_ligneId');
    debugPrint('🔄 Sens : $_sens');

    final gpsDisponible =
        await _locationService.verifierGPS(
      onErreur: (erreur) {
        debugPrint(
          '❌ GPS : $erreur',
        );

        if (mounted) {
          setState(() {
            _erreur = erreur;
          });
        }
      },
    );

    if (!gpsDisponible) {
      debugPrint(
        '❌ GPS non disponible.',
      );

      return;
    }

    debugPrint(
      '✅ GPS autorisé.',
    );

    // ============================================================
    // 2. CRÉER TRAJET
    // ============================================================

    debugPrint(
      '📤 Création du trajet Laravel...',
    );

    await ApiService.post(
      '/chauffeur/trajet/demarrer',
      {
        'bus_id': _busId,
        'ligne_id': _ligneId,
        'sens': _sens,
      },
    );

    trajetCree = true;

    debugPrint(
      '✅ Trajet créé.',
    );

    // ============================================================
    // 3. DÉMARRER PARTAGE GPS
    // ============================================================

    debugPrint(
      '📡 Démarrage du partage GPS...',
    );

    final partageDemarre =
        await _locationService.demarrerPartage(
      onErreur: (erreur) {
        debugPrint(
          '❌ PARTAGE GPS : $erreur',
        );

        if (mounted) {
          setState(() {
            _erreur = erreur;
          });
        }
      },
    );

    debugPrint(
      '📡 Résultat partage GPS : $partageDemarre',
    );

    // ============================================================
    // 4. GPS ÉCHOUÉ
    // ============================================================

    if (!partageDemarre) {
      debugPrint(
        '❌ Le partage GPS n’a pas démarré.',
      );

      if (trajetCree) {
        try {
          await ApiService.post(
            '/chauffeur/trajet/annuler',
            {},
          );

          debugPrint(
            '🛑 Trajet annulé.',
          );
        } catch (e) {
          debugPrint(
            '⚠️ Impossible d’annuler le trajet : $e',
          );
        }
      }

      if (mounted) {
        setState(() {
          _erreur =
              _erreur ??
              'Le partage GPS n’a pas pu démarrer. '
              'Vérifiez la localisation puis réessayez.';
        });
      }

      return;
    }

    // ============================================================
    // 5. TOUT EST OK
    // ============================================================

    debugPrint(
      '🎉 TRAJET DÉMARRÉ AVEC GPS !',
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  } on ApiException catch (error) {
    debugPrint(
      '❌ ERREUR API : ${error.message}',
    );

    if (mounted) {
      setState(() {
        _erreur =
            'Erreur serveur : ${error.message}';
      });
    }

    if (trajetCree) {
      try {
        await ApiService.post(
          '/chauffeur/trajet/annuler',
          {},
        );
      } catch (_) {}
    }
  } catch (error) {
    debugPrint(
      '❌ ERREUR : $error',
    );

    if (mounted) {
      setState(() {
        _erreur =
            'Une erreur est survenue : $error';
      });
    }

    if (trajetCree) {
      try {
        await ApiService.post(
          '/chauffeur/trajet/annuler',
          {},
        );
      } catch (_) {}
    }
  } finally {
    if (mounted) {
      setState(() {
        _envoi = false;
      });
    }

    debugPrint(
      '========== FIN DÉMARRAGE =========='
    );
  }
}

  // ==========================================================================
  // INTERFACE
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ==================================================================
          // APP BAR
          // ==================================================================

          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 16,
              ),
              title: const Text(
                'Préparer le trajet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
              ),
            ),
          ),

          // ==================================================================
          // CONTENU
          // ==================================================================

          SliverFillRemaining(
            hasScrollBody: false,
            child: _chargement
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
                          'Sélectionne le bus que tu conduis, '
                          'la ligne et le sens du trajet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ====================================================
                        // BUS
                        // ====================================================

                        if (_buses.isEmpty)
                          const _MessageInfo(
                            message:
                                "Aucun bus disponible pour le moment. "
                                "Un autre chauffeur circule peut-être déjà "
                                "sur tous les bus actifs, ou demande à un "
                                "administrateur d'en ajouter.",
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.lg,
                              ),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // ==========================================
                                // BUS
                                // ==========================================

                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration:
                                      const InputDecoration(
                                    labelText: 'Bus disponible',
                                    prefixIcon: Icon(
                                      Icons
                                          .directions_bus_filled_rounded,
                                    ),
                                  ),
                                  items: _buses
                                      .map(
                                        (bus) =>
                                            DropdownMenuItem<int>(
                                          value: bus.id,
                                          child: Text(
                                            '${bus.numero} - '
                                            '${bus.immatriculation}',
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _envoi
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _busId = value;
                                          });
                                        },
                                ),

                                const SizedBox(height: 16),

                                // ==========================================
                                // LIGNE
                                // ==========================================

                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration:
                                      const InputDecoration(
                                    labelText: 'Ligne',
                                    prefixIcon: Icon(
                                      Icons.alt_route_rounded,
                                    ),
                                  ),
                                  items: _lignes
                                      .map(
                                        (ligne) =>
                                            DropdownMenuItem<int>(
                                          value: ligne.id,
                                          child: Text(
                                            '${ligne.code} - '
                                            '${ligne.nom}',
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _envoi
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _ligneId = value;
                                          });
                                        },
                                ),

                                const SizedBox(height: 18),

                                // ==========================================
                                // SENS
                                // ==========================================

                                const Text(
                                  'Sens du trajet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _SensOption(
                                        label: 'Aller',
                                        icon: Icons
                                            .north_east_rounded,
                                        selected:
                                            _sens == 'aller',
                                        onTap: _envoi
                                            ? () {}
                                            : () {
                                                setState(() {
                                                  _sens = 'aller';
                                                });
                                              },
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: _SensOption(
                                        label: 'Retour',
                                        icon: Icons
                                            .south_west_rounded,
                                        selected:
                                            _sens == 'retour',
                                        onTap: _envoi
                                            ? () {}
                                            : () {
                                                setState(() {
                                                  _sens = 'retour';
                                                });
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // ====================================================
                        // ERREUR
                        // ====================================================

                        if (_erreur != null) ...[
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(
                                0.08,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.danger
                                    .withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    _erreur!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ====================================================
                        // BOUTON
                        // ====================================================

                        if (_buses.isNotEmpty) ...[
                          const SizedBox(height: 26),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _envoi ? null : _demarrer,
                              icon: _envoi
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.play_arrow_rounded,
                                    ),
                              label: Text(
                                _envoi
                                    ? 'Démarrage...'
                                    : 'Démarrer le trajet',
                              ),
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

// =============================================================================
// OPTION SENS
// =============================================================================

class _SensOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SensOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? AppColors.heroGradient
              : null,
          color: selected
              ? null
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),

            const SizedBox(height: 6),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MESSAGE INFO
// =============================================================================

class _MessageInfo extends StatelessWidget {
  final String message;

  const _MessageInfo({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(
          0.12,
        ),
        borderRadius: BorderRadius.circular(
          AppRadius.md,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accent,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
