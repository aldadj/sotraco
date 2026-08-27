```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bus.dart';
import '../../models/ligne.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

import '../splash_screen.dart';
import '../chauffeur/chauffeur_form_screen.dart';
import 'bus_form_screen.dart';
import 'ligne_form_screen.dart';
import 'fleet_map_screen.dart';

/// ============================================================
/// SOTRACO TRACK - ADMIN DASHBOARD
/// ============================================================
///
/// Aucun changement aux API, modèles ou providers.
/// Cette page utilise uniquement les données déjà disponibles
/// dans BusProvider.
///
/// Fonctionnalités UI :
/// - Dashboard général
/// - Statistiques flotte
/// - État GPS
/// - Carte réseau
/// - Activité récente
/// - Alertes
/// - Actions rapides
/// - Recherche de bus
/// - Filtres de flotte
/// - Cartes bus
/// - Cartes lignes
/// - Gestion CRUD existante
/// ============================================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _rechercheController =
      TextEditingController();

  String _filtreBus = 'Tous';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rafraichir();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rechercheController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DONNÉES
  // ==========================================================

  Future<void> _rafraichir() async {
    final provider = context.read<BusProvider>();

    await Future.wait([
      provider.chargerLignes(),
      provider.chargerBuses(),
    ]);

    if (mounted && provider.erreur != null) {
      _afficherErreur(provider.erreur!);
    }
  }

  List<Bus> _busFiltres(List<Bus> buses) {
    final recherche =
        _rechercheController.text.trim().toLowerCase();

    return buses.where((bus) {
      final correspondRecherche =
          recherche.isEmpty ||
          bus.numero.toLowerCase().contains(recherche) ||
          (bus.ligneNom ?? '')
              .toLowerCase()
              .contains(recherche) ||
          (bus.chauffeurNom ?? '')
              .toLowerCase()
              .contains(recherche);

      final correspondFiltre = switch (_filtreBus) {
        'En direct' => bus.enDirect,
        'En pause' => !bus.enDirect,
        _ => true,
      };

      return correspondRecherche && correspondFiltre;
    }).toList();
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> _ouvrirFormulaireBus({Bus? bus}) async {
    final busProvider = context.read<BusProvider>();

    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusFormScreen(
          bus: bus,
          lignes: busProvider.lignes,
        ),
      ),
    );

    if (resultat == true) {
      await _rafraichir();
    }
  }

  Future<void> _ouvrirFormulaireLigne({Ligne? ligne}) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LigneFormScreen(
          ligne: ligne,
        ),
      ),
    );

    if (resultat == true) {
      await _rafraichir();
    }
  }

  Future<void> _ouvrirFormulaireChauffeur() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChauffeurFormScreen(),
      ),
    );
  }

  void _ouvrirCarte() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FleetMapScreen(),
      ),
    );
  }

  Future<void> _deconnecter() async {
    final auth = context.read<AuthProvider>();

    await auth.deconnecter();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================================
  // SUPPRESSION
  // ==========================================================

  Future<void> _confirmerSuppressionBus(Bus bus) async {
    final confirme = await _confirmer(
      titre: 'Supprimer ce bus ?',
      message:
          '${bus.numero} sera définitivement supprimé.',
    );

    if (confirme != true) return;

    try {
      await AdminService.supprimerBus(bus.id);
      await _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  Future<void> _confirmerSuppressionLigne(
      Ligne ligne) async {
    final confirme = await _confirmer(
      titre: 'Supprimer cette ligne ?',
      message:
          '${ligne.nom} sera définitivement supprimée.',
    );

    if (confirme != true) return;

    try {
      await AdminService.supprimerLigne(ligne.id);
      await _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  Future<bool?> _confirmer({
    required String titre,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            titre,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),

      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 245,
              elevation: 0,
              backgroundColor: AppColors.primary,

              actions: [
                _HeaderAction(
                  icon: Icons.map_rounded,
                  tooltip: 'Carte de la flotte',
                  onPressed: _ouvrirCarte,
                ),
                _HeaderAction(
                  icon: Icons.person_add_alt_1_rounded,
                  tooltip: 'Ajouter un chauffeur',
                  onPressed:
                      _ouvrirFormulaireChauffeur,
                ),
                _HeaderAction(
                  icon: Icons.logout_rounded,
                  tooltip: 'Déconnexion',
                  onPressed: _deconnecter,
                ),
                const SizedBox(width: 8),
              ],

              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,

                background: _DashboardHeader(
                  nombreBus: provider.buses.length,
                  nombreLignes:
                      provider.lignes.length,
                  busDirect: provider.buses
                      .where((b) => b.enDirect)
                      .length,
                ),

                titlePadding:
                    const EdgeInsets.only(
                  left: 20,
                  bottom: 62,
                ),

                title: const Text(
                  'Administration',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              bottom: PreferredSize(
                preferredSize:
                    const Size.fromHeight(62),

                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    12,
                  ),
                  child: Container(
                    height: 50,
                    padding:
                        const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withOpacity(.13),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: TabBar(
                      controller: _tabController,

                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      indicatorSize:
                          TabBarIndicatorSize.tab,

                      labelColor:
                          AppColors.primaryDark,

                      unselectedLabelColor:
                          Colors.white,

                      labelStyle:
                          const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),

                      dividerColor:
                          Colors.transparent,

                      tabs: const [
                        Tab(
                          icon: Icon(
                            Icons.dashboard_rounded,
                            size: 18,
                          ),
                          text: 'Dashboard',
                        ),
                        Tab(
                          icon: Icon(
                            Icons.route_rounded,
                            size: 18,
                          ),
                          text: 'Réseau',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },

        body: TabBarView(
          controller: _tabController,
          children: [
            _DashboardTab(
              buses: provider.buses,
              lignes: provider.lignes,
              onRafraichir: _rafraichir,
              onCarte: _ouvrirCarte,
              onAjouterBus:
                  () => _ouvrirFormulaireBus(),
              onAjouterLigne:
                  () => _ouvrirFormulaireLigne(),
              onAjouterChauffeur:
                  _ouvrirFormulaireChauffeur,
              onModifierBus:
                  (bus) => _ouvrirFormulaireBus(
                    bus: bus,
                  ),
              onSupprimerBus:
                  _confirmerSuppressionBus,
            ),

            _ReseauTab(
              buses: provider.buses,
              lignes: provider.lignes,
              rechercheController:
                  _rechercheController,
              filtreBus: _filtreBus,
              onFiltreChanged: (value) {
                setState(() {
                  _filtreBus = value;
                });
              },
              onRechercheChanged: () {
                setState(() {});
              },
              onRafraichir: _rafraichir,
              onModifierBus:
                  (bus) => _ouvrirFormulaireBus(
                    bus: bus,
                  ),
              onSupprimerBus:
                  _confirmerSuppressionBus,
              onModifierLigne:
                  (ligne) => _ouvrirFormulaireLigne(
                    ligne: ligne,
                  ),
              onSupprimerLigne:
                  _confirmerSuppressionLigne,
            ),
          ],
        ),
      ),

      floatingActionButton:
          _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    final dashboard =
        _tabController.index == 0;

    return FloatingActionButton.extended(
      elevation: 10,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,

      onPressed: dashboard
          ? _ouvrirCarte
          : () => _ouvrirFormulaireBus(),

      icon: Icon(
        dashboard
            ? Icons.map_rounded
            : Icons.add_rounded,
      ),

      label: Text(
        dashboard
            ? 'Voir la flotte'
            : 'Ajouter un bus',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  final int nombreBus;
  final int nombreLignes;
  final int busDirect;

  const _DashboardHeader({
    required this.nombreBus,
    required this.nombreLignes,
    required this.busDirect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -50,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withOpacity(.055),
              ),
            ),
          ),

          Positioned(
            right: 20,
            bottom: 30,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 125,
              color: Colors.white
                  .withOpacity(.075),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 78,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(.13),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons
                            .space_dashboard_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SOTRACO TRACK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'Bonjour, Administrateur 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  '$nombreBus bus • '
                  '$nombreLignes lignes • '
                  '$busDirect en direct',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD PRINCIPAL
// ============================================================

class _DashboardTab extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;

  final Future<void> Function() onRafraichir;
  final VoidCallback onCarte;

  final VoidCallback onAjouterBus;
  final VoidCallback onAjouterLigne;
  final VoidCallback onAjouterChauffeur;

  final void Function(Bus) onModifierBus;
  final void Function(Bus) onSupprimerBus;

  const _DashboardTab({
    required this.buses,
    required this.lignes,
    required this.onRafraichir,
    required this.onCarte,
    required this.onAjouterBus,
    required this.onAjouterLigne,
    required this.onAjouterChauffeur,
    required this.onModifierBus,
    required this.onSupprimerBus,
  });

  @override
  Widget build(BuildContext context) {
    final direct =
        buses.where((b) => b.enDirect).length;

    final pause = buses.length - direct;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRafraichir,

      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          22,
          18,
          120,
        ),

        children: [
          // ----------------------------------------------------
          // KPI
          // ----------------------------------------------------

          _SectionTitle(
            titre: 'Vue d’ensemble',
            sousTitre:
                'État actuel du réseau SOTRACO',
          ),

          const SizedBox(height: 14),

          _KpiGrid(
            totalBus: buses.length,
            direct: direct,
            lignes: lignes.length,
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // CARTE
          // ----------------------------------------------------

          _LiveMapCard(
            totalBus: buses.length,
            direct: direct,
            onPressed: onCarte,
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // ÉTAT FLOTTE
          // ----------------------------------------------------

          _FleetStatusCard(
            total: buses.length,
            direct: direct,
            pause: pause,
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // ACTIONS
          // ----------------------------------------------------

          _SectionTitle(
            titre: 'Actions rapides',
            sousTitre:
                'Les outils les plus utilisés',
          ),

          const SizedBox(height: 13),

          _QuickActions(
            onAjouterBus: onAjouterBus,
            onAjouterLigne: onAjouterLigne,
            onAjouterChauffeur:
                onAjouterChauffeur,
            onCarte: onCarte,
          ),

          const SizedBox(height: 26),

          // ----------------------------------------------------
          // ACTIVITÉ
          // ----------------------------------------------------

          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  titre: 'Activité du réseau',
                  sousTitre:
                      'Dernières informations disponibles',
                ),
              ),
              _LiveBadge(),
            ],
          ),

          const SizedBox(height: 14),

          _ActivityCard(
            buses: buses,
            lignes: lignes,
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // ALERTES
          // ----------------------------------------------------

          _SectionTitle(
            titre: 'Surveillance',
            sousTitre:
                'Points nécessitant votre attention',
          ),

          const SizedBox(height: 14),

          _AlertsCard(
            buses: buses,
          ),

          const SizedBox(height: 26),

          // ----------------------------------------------------
          // LIGNES
          // ----------------------------------------------------

          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  titre: 'Lignes du réseau',
                  sousTitre:
                      'Aperçu des lignes enregistrées',
                ),
              ),
              Text(
                '${lignes.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (lignes.isEmpty)
            const _EmptyCard(
              icon: Icons.route_rounded,
              title:
                  'Aucune ligne enregistrée',
              subtitle:
                  'Ajoutez une ligne pour commencer.',
            )
          else
            ...lignes
                .take(5)
                .map(
                  (ligne) =>
                      _DashboardLineCard(
                    ligne: ligne,
                  ),
                ),

          const SizedBox(height: 26),

          // ----------------------------------------------------
          // FLOTTE
          // ----------------------------------------------------

          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  titre: 'Flotte en direct',
                  sousTitre:
                      'Bus actuellement enregistrés',
                ),
              ),
              if (buses.length > 5)
                Text(
                  '+${buses.length - 5}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (buses.isEmpty)
            const _EmptyCard(
              icon:
                  Icons.directions_bus_outlined,
              title:
                  'Aucun bus enregistré',
              subtitle:
                  'Ajoutez votre premier bus.',
            )
          else
            ...buses
                .take(5)
                .map(
                  (bus) => _DashboardBusCard(
                    bus: bus,
                    onModifier:
                        () => onModifierBus(
                      bus,
                    ),
                    onSupprimer:
                        () => onSupprimerBus(
                      bus,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ============================================================
// KPI
// ============================================================

class _KpiGrid extends StatelessWidget {
  final int totalBus;
  final int direct;
  final int lignes;

  const _KpiGrid({
    required this.totalBus,
    required this.direct,
    required this.lignes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.48,
      children: [
        _KpiCard(
          title: 'Bus enregistrés',
          value: '$totalBus',
          icon:
              Icons.directions_bus_filled_rounded,
          color: AppColors.primary,
          label: 'FLOTTE',
        ),
        _KpiCard(
          title: 'En circulation',
          value: '$direct',
          icon: Icons.gps_fixed_rounded,
          color: AppColors.busEnDirect,
          label: 'LIVE',
        ),
        _KpiCard(
          title: 'Lignes actives',
          value: '$lignes',
          icon: Icons.route_rounded,
          color: AppColors.accent,
          label: 'RÉSEAU',
        ),
        _KpiCard(
          title: 'Disponibilité',
          value: totalBus == 0
              ? '0%'
              : '${((direct / totalBus) * 100).round()}%',
          icon:
              Icons.speed_rounded,
          color: Colors.deepPurple,
          label: 'SERVICE',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String label;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.045),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(.11),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARTE RÉSEAU
// ============================================================

class _LiveMapCard extends StatelessWidget {
  final int totalBus;
  final int direct;
  final VoidCallback onPressed;

  const _LiveMapCard({
    required this.totalBus,
    required this.direct,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A25),
            Color(0xFF176044),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primary.withOpacity(.18),
            blurRadius: 25,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Faux réseau graphique
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _NetworkPainter(),
            ),
          ),

          Positioned(
            left: 20,
            top: 20,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(.13),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'RÉSEAU EN TEMPS RÉEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 18,
            top: 18,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(.12),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.busEnDirect,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$direct bus live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bus décoratifs
          const Positioned(
            left: 55,
            top: 88,
            child: _MapBusDot(),
          ),
          const Positioned(
            left: 145,
            top: 130,
            child: _MapBusDot(),
          ),
          const Positioned(
            right: 80,
            top: 92,
            child: _MapBusDot(),
          ),
          const Positioned(
            right: 145,
            bottom: 47,
            child: _MapBusDot(),
          ),

          Positioned(
            left: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalBus bus enregistrés',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Visualisez toute la flotte sur la carte',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 18,
            bottom: 18,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    AppColors.primary,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
              ),
              label: const Text(
                'Ouvrir',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBusDot extends StatelessWidget {
  const _MapBusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white
                .withOpacity(.3),
            blurRadius: 15,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        size: 17,
        color: AppColors.primary,
      ),
    );
  }
}

// ============================================================
// PAINTER RÉSEAU
// ============================================================

class _NetworkPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.white
          .withOpacity(.08)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * .62)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .25,
        size.width * .52,
        size.height * .55,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .82,
        size.width,
        size.height * .36,
      );

    final path2 = Path()
      ..moveTo(
        size.width * .15,
        0,
      )
      ..quadraticBezierTo(
        size.width * .38,
        size.height * .42,
        size.width * .78,
        size.height,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// ÉTAT FLOTTE
// ============================================================

class _FleetStatusCard
    extends StatelessWidget {
  final int total;
  final int direct;
  final int pause;

  const _FleetStatusCard({
    required this.total,
    required this.direct,
    required this.pause,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        total == 0 ? 0.0 : direct / total;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.045),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'État de la flotte',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Disponibilité actuelle',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(
                  color:
                      AppColors.busEnDirect,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor:
                  AppColors.surfaceMuted,
              valueColor:
                  const AlwaysStoppedAnimation(
                AppColors.busEnDirect,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              _FleetLegend(
                color:
                    AppColors.busEnDirect,
                label:
                    '$direct en circulation',
              ),
              const SizedBox(width: 10),
              _FleetLegend(
                color:
                    AppColors.busArrete,
                label:
                    '$pause en pause',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FleetLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _FleetLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color:
                    AppColors.textSecondary,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIONS RAPIDES
// ============================================================

class _QuickActions
    extends StatelessWidget {
  final VoidCallback onAjouterBus;
  final VoidCallback onAjouterLigne;
  final VoidCallback onAjouterChauffeur;
  final VoidCallback onCarte;

  const _QuickActions({
    required this.onAjouterBus,
    required this.onAjouterLigne,
    required this.onAjouterChauffeur,
    required this.onCarte,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon:
                Icons.directions_bus_filled_rounded,
            label: 'Ajouter\nun bus',
            color: AppColors.primary,
            onTap: onAjouterBus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.route_rounded,
            label: 'Ajouter\nune ligne',
            color: AppColors.accent,
            onTap: onAjouterLigne,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon:
                Icons.person_add_alt_1_rounded,
            label: 'Ajouter\nchauffeur',
            color: Colors.deepPurple,
            onTap: onAjouterChauffeur,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.map_rounded,
            label: 'Voir\nla carte',
            color: Colors.orange,
            onTap: onCarte,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 14,
          ),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVITÉ
// ============================================================

class _ActivityCard
    extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;

  const _ActivityCard({
    required this.buses,
    required this.lignes,
  });

  @override
  Widget build(BuildContext context) {
    final directs =
        buses.where((b) => b.enDirect).toList();

    if (buses.isEmpty) {
      return const _EmptyCard(
        icon: Icons.timeline_rounded,
        title: 'Aucune activité',
        subtitle:
            'Les activités apparaîtront ici.',
      );
    }

    final items = <Widget>[];

    if (directs.isNotEmpty) {
      final bus = directs.first;

      items.add(
        _ActivityItem(
          icon:
              Icons.gps_fixed_rounded,
          color:
              AppColors.busEnDirect,
          title:
              '${bus.numero} est en circulation',
          subtitle:
              '${bus.ligneNom ?? "Ligne non assignée"} • GPS actif',
        ),
      );
    }

    if (buses.length > 1) {
      final bus = buses[1];

      items.add(
        _ActivityItem(
          icon:
              Icons.directions_bus_rounded,
          color:
              AppColors.primary,
          title:
              'Bus ${bus.numero} enregistré',
          subtitle:
              '${bus.ligneNom ?? "Aucune ligne"} • ${bus.statut}',
        ),
      );
    }

    if (lignes.isNotEmpty) {
      items.add(
        _ActivityItem(
          icon: Icons.route_rounded,
          color: AppColors.accent,
          title:
              'Réseau opérationnel',
          subtitle:
              '${lignes.length} ligne(s) disponible(s)',
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0;
              i < items.length;
              i++) ...[
            items[i],
            if (i != items.length - 1)
              const Divider(
                height: 22,
                color:
                    Color(0xFFEFF1F3),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivityItem
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'maintenant',
          style: TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ALERTES
// ============================================================

class _AlertsCard extends StatelessWidget {
  final List<Bus> buses;

  const _AlertsCard({
    required this.buses,
  });

  @override
  Widget build(BuildContext context) {
    final pauses =
        buses.where((b) => !b.enDirect).length;

    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          if (pauses > 0)
            _AlertItem(
              icon:
                  Icons.pause_circle_outline_rounded,
              color: Colors.orange,
              title:
                  '$pauses bus en pause',
              subtitle:
                  'Ces bus ne transmettent actuellement pas leur position.',
            )
          else
            const _AlertItem(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.busEnDirect,
              title: 'Tout fonctionne correctement',
              subtitle:
                  'Aucun bus en pause actuellement.',
            ),

          const Divider(
            height: 22,
          ),

          const _AlertItem(
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            title: 'Système opérationnel',
            subtitle:
                'Les services SOTRACO TRACK sont disponibles.',
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color:
                color.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CARTE LIGNE DASHBOARD
// ============================================================

class _DashboardLineCard
    extends StatelessWidget {
  final Ligne ligne;

  const _DashboardLineCard({
    required this.ligne,
  });

  Color _getColor() {
    try {
      return Color(
        int.parse(
          ligne.couleur
              .replaceFirst('#', '0xFF'),
        ),
      );
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 15,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                ligne.code,
                style: TextStyle(
                  color: color,
                  fontWeight:
                      FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.nom,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ligne.depart ?? '?',
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 7,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: color,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ligne.destination ?? '?',
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Text(
              '${ligne.busesCount ?? 0} bus',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARTE BUS DASHBOARD
// ============================================================

class _DashboardBusCard
    extends StatelessWidget {
  final Bus bus;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _DashboardBusCard({
    required this.bus,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final direct = bus.enDirect;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: direct
                  ? AppColors.heroGradient
                  : null,
              color: direct
                  ? null
                  : AppColors.surfaceMuted,
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: direct
                  ? Colors.white
                  : AppColors.busArrete,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bus.numero,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      direct: direct,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bus.ligneNom ??
                      'Ligne non assignée',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              color:
                  AppColors.textSecondary,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'modifier') {
                onModifier();
              }
              if (value == 'supprimer') {
                onSupprimer();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'modifier',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                    ),
                    SizedBox(width: 9),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color:
                          AppColors.danger,
                      size: 18,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Supprimer',
                      style: TextStyle(
                        color:
                            AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONGLET RÉSEAU
// ============================================================

class _ReseauTab
    extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;

  final TextEditingController
      rechercheController;

  final String filtreBus;

  final void Function(String)
      onFiltreChanged;

  final VoidCallback onRechercheChanged;

  final Future<void> Function()
      onRafraichir;

  final void Function(Bus)
      onModifierBus;

  final void Function(Bus)
      onSupprimerBus;

  final void Function(Ligne)
      onModifierLigne;

  final void Function(Ligne)
      onSupprimerLigne;

  const _ReseauTab({
    required this.buses,
    required this.lignes,
    required this.rechercheController,
    required this.filtreBus,
    required this.onFiltreChanged,
    required this.onRechercheChanged,
    required this.onRafraichir,
    required this.onModifierBus,
    required this.onSupprimerBus,
    required this.onModifierLigne,
    required this.onSupprimerLigne,
  });

  List<Bus> _filtrer() {
    final query =
        rechercheController.text
            .trim()
            .toLowerCase();

    return buses.where((bus) {
      final search =
          query.isEmpty ||
          bus.numero
              .toLowerCase()
              .contains(query) ||
          (bus.ligneNom ?? '')
              .toLowerCase()
              .contains(query) ||
          (bus.chauffeurNom ?? '')
              .toLowerCase()
              .contains(query);

      final filter = switch (filtreBus) {
        'En direct' => bus.enDirect,
        'En pause' => !bus.enDirect,
        _ => true,
      };

      return search && filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtrer();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRafraichir,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          22,
          18,
          120,
        ),
        children: [
          const _SectionTitle(
            titre: 'Gestion du réseau',
            sousTitre:
                'Gérez vos bus et vos lignes',
          ),

          const SizedBox(height: 18),

          // Recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(.035),
                  blurRadius: 15,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller:
                  rechercheController,
              onChanged: (_) =>
                  onRechercheChanged(),
              decoration:
                  const InputDecoration(
                hintText:
                    'Rechercher un bus, une ligne...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          // Filtres
          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected:
                      filtreBus == 'Tous',
                  onTap: () =>
                      onFiltreChanged(
                    'Tous',
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En direct',
                  selected:
                      filtreBus ==
                          'En direct',
                  onTap: () =>
                      onFiltreChanged(
                    'En direct',
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En pause',
                  selected:
                      filtreBus ==
                          'En pause',
                  onTap: () =>
                      onFiltreChanged(
                    'En pause',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Flotte',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${filtered.length} bus',
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          if (filtered.isEmpty)
            const _EmptyCard(
              icon:
                  Icons.search_off_rounded,
              title:
                  'Aucun résultat',
              subtitle:
                  'Aucun bus ne correspond à votre recherche.',
            )
          else
            ...filtered.map(
              (bus) => _DashboardBusCard(
                bus: bus,
                onModifier:
                    () => onModifierBus(
                  bus,
                ),
                onSupprimer:
                    () => onSupprimerBus(
                  bus,
                ),
              ),
            ),

          const SizedBox(height: 25),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lignes',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${lignes.length} lignes',
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          if (lignes.isEmpty)
            const _EmptyCard(
              icon:
                  Icons.route_outlined,
              title:
                  'Aucune ligne',
              subtitle:
                  'Aucune ligne enregistrée.',
            )
          else
            ...lignes.map(
              (ligne) => _NetworkLineCard(
                ligne: ligne,
                onModifier:
                    () => onModifierLigne(
                  ligne,
                ),
                onSupprimer:
                    () => onSupprimerLigne(
                  ligne,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// LIGNE RÉSEAU
// ============================================================

class _NetworkLineCard
    extends StatelessWidget {
  final Ligne ligne;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _NetworkLineCard({
    required this.ligne,
    required this.onModifier,
    required this.onSupprimer,
  });

  Color _color() {
    try {
      return Color(
        int.parse(
          ligne.couleur
              .replaceFirst('#', '0xFF'),
        ),
      );
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Container(
      margin:
          const EdgeInsets.only(bottom: 13),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    ligne.code,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      ligne.nom,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${ligne.busesCount ?? 0} bus affecté(s)',
                      style:
                          const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert_rounded,
                ),
                onSelected: (value) {
                  if (value == 'modifier') {
                    onModifier();
                  }
                  if (value == 'supprimer') {
                    onSupprimer();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'modifier',
                    child: Text('Modifier'),
                  ),
                  PopupMenuItem(
                    value: 'supprimer',
                    child: Text(
                      'Supprimer',
                      style: TextStyle(
                        color:
                            AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  color.withOpacity(.055),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _RoutePoint(
                  label:
                      ligne.depart ?? '?',
                  color: color,
                ),

                Expanded(
                  child: Container(
                    height: 2,
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                    ),
                    color:
                        color.withOpacity(.25),
                  ),
                ),

                Icon(
                  Icons.directions_bus_rounded,
                  size: 17,
                  color: color,
                ),

                Expanded(
                  child: Container(
                    height: 2,
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                    ),
                    color:
                        color.withOpacity(.25),
                  ),
                ),

                _RoutePoint(
                  label:
                      ligne.destination ?? '?',
                  color: color,
                  end: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint
    extends StatelessWidget {
  final String label;
  final Color color;
  final bool end;

  const _RoutePoint({
    required this.label,
    required this.color,
    this.end = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment:
            end
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: end
                  ? Colors.white
                  : color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                end
                    ? TextAlign.right
                    : TextAlign.left,
            style: const TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS GÉNÉRAUX
// ============================================================

class _SectionTitle
    extends StatelessWidget {
  final String titre;
  final String sousTitre;

  const _SectionTitle({
    required this.titre,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sousTitre,
          style: const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _HeaderAction
    extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor:
              Colors.white.withOpacity(.12),
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  final bool direct;

  const _StatusBadge({
    required this.direct,
  });

  @override
  Widget build(BuildContext context) {
    final color = direct
        ? AppColors.busEnDirect
        : AppColors.textSecondary;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            direct ? 'LIVE' : 'PAUSE',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.busEnDirect
            .withOpacity(.09),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(
              color:
                  AppColors.busEnDirect,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color:
                  AppColors.busEnDirect,
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary
          : Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 9,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  AppColors.primary
                      .withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  AppColors.primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
```
