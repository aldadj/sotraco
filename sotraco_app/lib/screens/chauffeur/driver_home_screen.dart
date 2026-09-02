import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../passager/home_screen.dart';
import '../splash_screen.dart';
import 'start_trip_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();

  bool _partageActif = false;
  bool _chargement = false;
  bool _chargementTrajet = true;

  String? _erreur;
  Map<String, dynamic>? _trajetActif;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _chargerTrajetActif();
  }

  // ==========================================================================
  // CHARGER LE TRAJET ACTIF
  // ==========================================================================

  Future<void> _chargerTrajetActif() async {
    if (!mounted) return;

    setState(() {
      _chargementTrajet = true;
      _erreur = null;
    });

    try {
      final data = await ApiService.get('/chauffeur/trajet-actif');

      if (!mounted) return;

      final trajetExiste =
          data is Map && data['trajet_actif'] == true;

      Map<String, dynamic>? trajet;

      if (trajetExiste && data['trajet'] != null) {
        trajet = Map<String, dynamic>.from(
          data['trajet'] as Map,
        );
      }

      final bus = trajet?['bus'];

      bool gpsActif = false;

      if (bus is Map) {
        gpsActif = bus['en_marche'] == true;
      }

      setState(() {
        _trajetActif = trajet;
        _partageActif = gpsActif;
        _chargementTrajet = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _erreur = error.message;
        _chargementTrajet = false;
        _trajetActif = null;
        _partageActif = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _erreur = error.toString();
        _chargementTrajet = false;
      });
    }
  }

  // ==========================================================================
  // PRÉPARER UN TRAJET
  // ==========================================================================

  Future<void> _preparerTrajet() async {
    if (_chargement) return;

    final demarre = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const StartTripScreen(),
      ),
    );

    if (demarre != true || !mounted) return;

    await _chargerTrajetActif();

    if (!mounted) return;

    if (_trajetActif != null && !_partageActif) {
      await _demarrerGPS();
    }
  }

  // ==========================================================================
  // DÉMARRER / ARRÊTER LE GPS
  // ==========================================================================

  Future<void> _basculerPartage() async {
    if (_trajetActif == null) {
      await _preparerTrajet();
      return;
    }

    if (_partageActif) {
      await _arreterGPS();
    } else {
      await _demarrerGPS();
    }
  }

  Future<void> _demarrerGPS() async {
    if (_trajetActif == null || _chargement) return;

    if (!mounted) return;

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final succes = await _locationService.demarrerPartage(
        onErreur: (message) {
          if (!mounted) return;

          setState(() {
            _erreur = message;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _partageActif = succes;
        _chargement = false;
      });

      if (!succes) {
        await _chargerTrajetActif();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _partageActif = false;
        _chargement = false;
        _erreur = error.toString();
      });
    }
  }

  Future<void> _arreterGPS() async {
    if (_chargement) return;

    if (!mounted) return;

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await _locationService.arreterPartage();

      if (!mounted) return;

      setState(() {
        _partageActif = false;
        _chargement = false;
      });

      await _chargerTrajetActif();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _chargement = false;
        _erreur = error.toString();
      });
    }
  }

Future<bool> _terminerTrajet({
  bool demanderConfirmation = true,
}) async {
  if (_trajetActif == null || _chargement) {
    return false;
  }

  if (demanderConfirmation) {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppColors.danger,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terminer le trajet',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment terminer ce trajet ? '
            'Vous pourrez ensuite choisir un autre bus ou une autre ligne.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Terminer'),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) {
      return false;
    }
  }

  setState(() {
    _chargement = true;
    _erreur = null;
  });

  try {
    // Si le GPS est encore actif, on arrête d'abord le partage.
    if (_partageActif) {
      await _locationService.arreterPartage();
    }

    // On termine réellement le trajet côté Laravel.
    await ApiService.post(
      '/chauffeur/trajet/terminer',
      {},
    );

    if (!mounted) {
      return true;
    }

    setState(() {
      _trajetActif = null;
      _partageActif = false;
      _chargement = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trajet terminé avec succès.'),
      ),
    );

    return true;
  } on ApiException catch (error) {
    if (!mounted) {
      return false;
    }

    setState(() {
      _chargement = false;
      _erreur = error.message;
    });

    return false;
  } catch (error) {
    if (!mounted) {
      return false;
    }

    setState(() {
      _chargement = false;
      _erreur = error.toString();
    });

    return false;
  }
}
  // ==========================================================================
  // CHANGER DE TRAJET
  // ==========================================================================

  Future<void> _changerTrajet() async {
  if (_partageActif) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Arrêtez d’abord le suivi GPS avant de changer de trajet.',
        ),
      ),
    );
    return;
  }

  final confirmer = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Changer de trajet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Le trajet actuel sera terminé et vous pourrez ensuite choisir un autre bus ou une autre ligne.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      );
    },
  );

  if (confirmer != true || !mounted) {
    return;
  }

  // Le trajet existant doit être réellement terminé
  // avant d'en préparer un nouveau.
  final termine = await _terminerTrajet(
    demanderConfirmation: false,
  );

  if (!termine || !mounted) {
    return;
  }

  await _preparerTrajet();
}

  // ==========================================================================
  // DÉCONNEXION
  // ==========================================================================

  Future<void> _deconnecter(AuthProvider auth) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte chauffeur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) return;

    if (_partageActif) {
  await _locationService.arreterPartage();
}

if (_trajetActif != null) {
  try {
    await ApiService.post(
      '/chauffeur/trajet/terminer',
      {},
    );
  } on ApiException catch (error) {
    if (!mounted) return;

    setState(() {
      _erreur = error.message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Impossible de terminer le trajet : ${error.message}',
        ),
      ),
    );

    return;
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _erreur = error.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Impossible de terminer le trajet : $error',
        ),
      ),
    );

    return;
  }
}

await auth.deconnecter();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================================================
  // HEURE DU TRAJET
  // ==========================================================================

  String _heureTrajet() {
    final debut = _trajetActif?['debut_a'];

    if (debut == null) {
      return '--:--';
    }

    try {
      final date = DateTime.parse(
        debut.toString(),
      ).toLocal();

      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationService.dispose();

    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final prenom =
        auth.user?.name.split(' ').first ?? 'Chauffeur';

    final bus = _trajetActif?['bus'];
    final ligne = _trajetActif?['ligne'];

    final numeroBus =
        bus is Map
            ? bus['numero']?.toString() ?? '--'
            : '--';

    final nomLigne =
        ligne is Map
            ? ligne['nom']?.toString() ?? 'Ligne non définie'
            : 'Ligne non définie';

    final sens =
        _trajetActif?['sens']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _chargerTrajetActif,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // =================================================================
            // APP BAR
            // =================================================================

            SliverAppBar(
              pinned: true,
              expandedHeight: 190,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primary,
              elevation: 0,

              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.white.withOpacity(0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              actions: [
                IconButton(
                  tooltip: 'Actualiser',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                  onPressed:
                      _chargementTrajet
                          ? null
                          : _chargerTrajetActif,
                ),

                IconButton(
                  tooltip: 'Voir les bus',
                  icon: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PassengerHomeScreen(),
                      ),
                    );
                  },
                ),

                IconButton(
                  tooltip: 'Déconnexion',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                  ),
                  onPressed:
                      _chargement
                          ? null
                          : () => _deconnecter(auth),
                ),

                const SizedBox(width: 4),
              ],

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        76,
                        24,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bonjour, $prenom 👋',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Espace professionnel chauffeur',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Row(
                            children: [
                              _StatusPill(
                                icon: _partageActif
                                    ? Icons.location_on_rounded
                                    : Icons.location_off_rounded,
                                label: _partageActif
                                    ? 'GPS EN DIRECT'
                                    : 'GPS INACTIF',
                                actif: _partageActif,
                              ),

                              const SizedBox(width: 10),

                              if (_trajetActif != null)
                                _StatusPill(
                                  icon:
                                      Icons.directions_bus_rounded,
                                  label: 'BUS $numeroBus',
                                  actif: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // =================================================================
            // CONTENU
            // =================================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  32,
                ),
                child: Column(
                  children: [
                    if (_chargementTrajet)
                      const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      // =======================================================
                      // AUCUN TRAJET
                      // =======================================================

                      if (_trajetActif == null)
                        _AucunTrajetCard(
                          onCommencer: _preparerTrajet,
                        ),

                      // =======================================================
                      // TRAJET ACTIF
                      // =======================================================

                      if (_trajetActif != null) ...[
                        _TrajetCard(
                          numeroBus: numeroBus,
                          nomLigne: nomLigne,
                          sens: sens,
                          heure: _heureTrajet(),
                          partageActif: _partageActif,
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _partageActif ||
                                        _chargement
                                    ? null
                                    : _changerTrajet,
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                            ),
                            label: const Text(
                              'Changer de trajet',
                            ),
                            style:
                                OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _chargement
                                  ? null
                                  : _terminerTrajet,
                          icon: const Icon(
                            Icons.flag_rounded,
                          ),
                          label: const Text(
                            'Terminer le trajet',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      ],

                      const SizedBox(height: 30),

                      // =======================================================
                      // BOUTON GPS
                      // =======================================================

                      GestureDetector(
                        onTap: _chargement
                            ? null
                            : _basculerPartage,
                        child: SizedBox(
                          width: 235,
                          height: 235,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_partageActif)
                                AnimatedBuilder(
                                  animation:
                                      _pulseController,
                                  builder:
                                      (context, child) {
                                    final scale =
                                        1 +
                                        _pulseController
                                                .value *
                                            0.45;

                                    final opacity =
                                        (1 -
                                                _pulseController
                                                    .value)
                                            .clamp(
                                          0.0,
                                          1.0,
                                        );

                                    return Transform.scale(
                                      scale: scale,
                                      child: Opacity(
                                        opacity:
                                            opacity * 0.25,
                                        child: Container(
                                          width: 190,
                                          height: 190,
                                          decoration:
                                              const BoxDecoration(
                                            color: AppColors
                                                .busEnDirect,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds: 350,
                                ),
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _partageActif
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.danger,
                                            Color(0xFFB92E44),
                                          ],
                                        )
                                      : AppColors.heroGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_partageActif
                                                  ? AppColors.danger
                                                  : AppColors.primary)
                                              .withOpacity(0.35),
                                      blurRadius: 32,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _chargement
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _trajetActif ==
                                                      null
                                                  ? Icons
                                                      .route_rounded
                                                  : _partageActif
                                                      ? Icons
                                                          .stop_circle_rounded
                                                      : Icons
                                                          .location_searching_rounded,
                                              color:
                                                  Colors.white,
                                              size: 50,
                                            ),

                                            const SizedBox(
                                              height: 10,
                                            ),

                                            Text(
                                              _trajetActif ==
                                                      null
                                                  ? 'Commencer\nun trajet'
                                                  : _partageActif
                                                      ? 'Arrêter le\nsuivi GPS'
                                                      : 'Démarrer le\nsuivi GPS',
                                              textAlign:
                                                  TextAlign.center,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.white,
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w800,
                                                height: 1.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _trajetActif == null
                            ? 'Choisissez votre bus et votre ligne.'
                            : _partageActif
                                ? 'Votre position est actuellement transmise.'
                                : 'Appuyez pour rendre votre bus visible.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      // =======================================================
                      // ERREUR
                      // =======================================================

                      if (_erreur != null) ...[
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.danger
                                  .withOpacity(0.2),
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

                      const SizedBox(height: 28),

                      // =======================================================
                      // CONSEILS
                      // =======================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .tips_and_updates_rounded,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Conseils de service',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            const _Conseil(
                              icon: Icons.gps_fixed_rounded,
                              text:
                                  'Activez la localisation de votre téléphone.',
                            ),

                            const SizedBox(height: 12),

                            const _Conseil(
                              icon: Icons
                                  .battery_charging_full_rounded,
                              text:
                                  'Gardez votre téléphone suffisamment chargé.',
                            ),

                            const SizedBox(height: 12),

                            const _Conseil(
                              icon: Icons.wifi_rounded,
                              text:
                                  'Une connexion Internet est nécessaire pour le suivi en direct.',
                            ),

                            const SizedBox(height: 12),

                            const _Conseil(
                              icon: Icons
                                  .phone_android_rounded,
                              text:
                                  'Évitez de fermer complètement l’application pendant le trajet.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// STATUT APP BAR
// ==========================================================================

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool actif;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.actif,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          actif ? 0.20 : 0.12,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// AUCUN TRAJET
// ==========================================================================

class _AucunTrajetCard extends StatelessWidget {
  final VoidCallback onCommencer;

  const _AucunTrajetCard({
    required this.onCommencer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Aucun trajet en cours',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Sélectionnez votre bus, votre ligne et votre sens de circulation avant de démarrer le suivi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCommencer,
              icon: const Icon(
                Icons.add_road_rounded,
              ),
              label: const Text(
                'Préparer mon trajet',
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CARTE TRAJET
// ==========================================================================

class _TrajetCard extends StatelessWidget {
  final String numeroBus;
  final String nomLigne;
  final String sens;
  final String heure;
  final bool partageActif;

  const _TrajetCard({
    required this.numeroBus,
    required this.nomLigne,
    required this.sens,
    required this.heure,
    required this.partageActif,
  });

  @override
  Widget build(BuildContext context) {
    final estAller = sens == 'aller';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRAJET EN COURS',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Bus $numeroBus',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: partageActif
                      ? AppColors.busEnDirect
                          .withOpacity(0.10)
                      : Colors.orange
                          .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      partageActif
                          ? Icons.circle
                          : Icons
                              .pause_circle_outline_rounded,
                      size: 10,
                      color: partageActif
                          ? AppColors.busEnDirect
                          : Colors.orange,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      partageActif
                          ? 'EN DIRECT'
                          : 'EN PAUSE',
                      style: TextStyle(
                        color: partageActif
                            ? AppColors.busEnDirect
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        nomLigne,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _InfoTrajet(
                        icon: estAller
                            ? Icons
                                .north_east_rounded
                            : Icons
                                .south_west_rounded,
                        titre: 'Direction',
                        valeur: estAller
                            ? 'Aller'
                            : 'Retour',
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 42,
                      color: Colors.black12,
                    ),

                    Expanded(
                      child: _InfoTrajet(
                        icon:
                            Icons.schedule_rounded,
                        titre: 'Départ',
                        valeur: heure,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTrajet extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String valeur;

  const _InfoTrajet({
    required this.icon,
    required this.titre,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 10,
              ),
            ),

            Text(
              valeur,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================================================
// CONSEIL
// ==========================================================================

class _Conseil extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Conseil({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color:
                AppColors.primary.withOpacity(0.08),
            borderRadius:
                BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}