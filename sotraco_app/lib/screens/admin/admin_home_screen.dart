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
/// SOTRACO TRACK
/// ADMIN HOME - DASHBOARD DE SUPERVISION
/// ============================================================
///
/// Aucun changement :
/// - API
/// - modèles
/// - providers
/// - services
/// - routes
///
/// Cette version travaille uniquement sur l'interface.
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

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> _ouvrirFormulaireBus({Bus? bus}) async {
    final provider = context.read<BusProvider>();

    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusFormScreen(
          bus: bus,
          lignes: provider.lignes,
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
      (_) => false,
    );
  }

  // ==========================================================
  // SUPPRESSION
  // ==========================================================

  Future<void> _confirmerSuppressionBus(Bus bus) async {
    final confirme = await _confirmer(
      titre: 'Supprimer le bus ?',
      message: '${bus.numero} sera définitivement supprimé.',
    );

    if (confirme != true) return;

    try {
      await AdminService.supprimerBus(bus.id);
      await _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  Future<void> _confirmerSuppressionLigne(Ligne ligne) async {
    final confirme = await _confirmer(
      titre: 'Supprimer la ligne ?',
      message: '${ligne.nom} sera définitivement supprimée.',
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
            borderRadius: BorderRadius.circular(18),
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
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
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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

    final direct = provider.buses.where((b) => b.enDirect).length;
    final pause = provider.buses.length - direct;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,

        titleSpacing: 18,

        title: const Row(
          children: [
            _BrandMark(),
            SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOTRACO TRACK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Centre de supervision',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          _TopIconButton(
            icon: Icons.map_outlined,
            tooltip: 'Carte',
            onPressed: _ouvrirCarte,
          ),
          _TopIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualiser',
            onPressed: _rafraichir,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) {
              if (value == 'chauffeur') {
                _ouvrirFormulaireChauffeur();
              }

              if (value == 'logout') {
                _deconnecter();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'chauffeur',
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded),
                    SizedBox(width: 10),
                    Text('Ajouter chauffeur'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
        ],
      ),

      body: Column(
        children: [
          // ====================================================
          // BANDEAU SUPERVISION
          // ====================================================

          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18,
            ),
            child: _SupervisionBanner(
              total: provider.buses.length,
              direct: direct,
              pause: pause,
            ),
          ),

          // ====================================================
          // ONGLETS
          // ====================================================

          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(
                  icon: Icon(
                    Icons.dashboard_rounded,
                    size: 19,
                  ),
                  text: 'Vue générale',
                ),
                Tab(
                  icon: Icon(
                    Icons.directions_bus_rounded,
                    size: 19,
                  ),
                  text: 'Flotte & réseau',
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DashboardView(
                  buses: provider.buses,
                  lignes: provider.lignes,
                  direct: direct,
                  pause: pause,
                  onCarte: _ouvrirCarte,
                  onAjouterBus: () => _ouvrirFormulaireBus(),
                  onAjouterLigne: () => _ouvrirFormulaireLigne(),
                  onAjouterChauffeur:
                      _ouvrirFormulaireChauffeur,
                  onModifierBus: (bus) =>
                      _ouvrirFormulaireBus(bus: bus),
                  onSupprimerBus: _confirmerSuppressionBus,
                ),

                _FleetView(
                  buses: provider.buses,
                  lignes: provider.lignes,
                  controller: _rechercheController,
                  filtre: _filtreBus,
                  onFilter: (value) {
                    setState(() {
                      _filtreBus = value;
                    });
                  },
                  onSearch: () => setState(() {}),
                  onModifierBus: (bus) =>
                      _ouvrirFormulaireBus(bus: bus),
                  onSupprimerBus: _confirmerSuppressionBus,
                  onModifierLigne: (ligne) =>
                      _ouvrirFormulaireLigne(ligne: ligne),
                  onSupprimerLigne:
                      _confirmerSuppressionLigne,
                  onAjouterBus: () => _ouvrirFormulaireBus(),
                  onAjouterLigne:
                      () => _ouvrirFormulaireLigne(),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 5,
        onPressed: _tabController.index == 0
            ? _ouvrirCarte
            : () => _ouvrirFormulaireBus(),
        child: Icon(
          _tabController.index == 0
              ? Icons.map_rounded
              : Icons.add_rounded,
        ),
      ),
    );
  }
}

// ============================================================
// LOGO
// ============================================================

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.directions_bus_filled_rounded,
        color: AppColors.primary,
        size: 23,
      ),
    );
  }
}

// ============================================================
// BOUTON HEADER
// ============================================================

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(.10),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ============================================================
// BANDEAU SUPERVISION
// ============================================================

class _SupervisionBanner extends StatelessWidget {
  final int total;
  final int direct;
  final int pause;

  const _SupervisionBanner({
    required this.total,
    required this.direct,
    required this.pause,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        total == 0 ? 0 : ((direct / total) * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bonjour, Administrateur 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$direct bus en circulation • $pause en pause',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          width: 67,
          height: 67,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(.10),
            border: Border.all(
              color: Colors.white.withOpacity(.22),
              width: 5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class _DashboardView extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;
  final int direct;
  final int pause;

  final VoidCallback onCarte;
  final VoidCallback onAjouterBus;
  final VoidCallback onAjouterLigne;
  final VoidCallback onAjouterChauffeur;

  final void Function(Bus) onModifierBus;
  final void Function(Bus) onSupprimerBus;

  const _DashboardView({
    required this.buses,
    required this.lignes,
    required this.direct,
    required this.pause,
    required this.onCarte,
    required this.onAjouterBus,
    required this.onAjouterLigne,
    required this.onAjouterChauffeur,
    required this.onModifierBus,
    required this.onSupprimerBus,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          100,
        ),
        children: [
          // ==================================================
          // STATISTIQUES
          // ==================================================

          const _DashboardSectionTitle(
            title: 'Vue d’ensemble',
            subtitle: 'État actuel du réseau',
          ),

          const SizedBox(height: 12),

          _StatsGrid(
            totalBus: buses.length,
            direct: direct,
            pause: pause,
            lignes: lignes.length,
          ),

          const SizedBox(height: 20),

          // ==================================================
          // CENTRE DE CONTRÔLE
          // ==================================================

          _ControlCenter(
            buses: buses,
            direct: direct,
            onCarte: onCarte,
          ),

          const SizedBox(height: 20),

          // ==================================================
          // ACTIONS
          // ==================================================

          const _DashboardSectionTitle(
            title: 'Actions rapides',
            subtitle: 'Gestion de votre réseau',
          ),

          const SizedBox(height: 12),

          _QuickActions(
            onAjouterBus: onAjouterBus,
            onAjouterLigne: onAjouterLigne,
            onAjouterChauffeur: onAjouterChauffeur,
            onCarte: onCarte,
          ),

          const SizedBox(height: 22),

          // ==================================================
          // ÉTAT DU RÉSEAU
          // ==================================================

          const _DashboardSectionTitle(
            title: 'État du réseau',
            subtitle: 'Informations importantes',
          ),

          const SizedBox(height: 12),

          _NetworkOverview(
            buses: buses,
            lignes: lignes,
            direct: direct,
            pause: pause,
          ),

          const SizedBox(height: 22),

          // ==================================================
          // ACTIVITÉ
          // ==================================================

          Row(
            children: [
              const Expanded(
                child: _DashboardSectionTitle(
                  title: 'Activité récente',
                  subtitle: 'Dernières informations',
                ),
              ),
              _LiveIndicator(),
            ],
          ),

          const SizedBox(height: 12),

          _ActivityPanel(
            buses: buses,
            lignes: lignes,
          ),

          const SizedBox(height: 22),

          // ==================================================
          // BUS
          // ==================================================

          Row(
            children: [
              const Expanded(
                child: _DashboardSectionTitle(
                  title: 'Flotte',
                  subtitle: 'Aperçu des bus',
                ),
              ),
              Text(
                '${buses.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (buses.isEmpty)
            const _EmptyPanel(
              icon: Icons.directions_bus_outlined,
              title: 'Aucun bus',
              subtitle: 'Votre flotte apparaîtra ici.',
            )
          else
            ...buses
                .take(5)
                .map(
                  (bus) => _CompactBusTile(
                    bus: bus,
                    onModifier: () => onModifierBus(bus),
                    onSupprimer: () => onSupprimerBus(bus),
                  ),
                ),

          const SizedBox(height: 22),

          // ==================================================
          // LIGNES
          // ==================================================

          Row(
            children: [
              const Expanded(
                child: _DashboardSectionTitle(
                  title: 'Lignes',
                  subtitle: 'Réseau disponible',
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

          const SizedBox(height: 12),

          if (lignes.isEmpty)
            const _EmptyPanel(
              icon: Icons.route_outlined,
              title: 'Aucune ligne',
              subtitle: 'Ajoutez une ligne au réseau.',
            )
          else
            ...lignes
                .take(5)
                .map(
                  (ligne) => _CompactLineTile(
                    ligne: ligne,
                  ),
                ),
        ],
      ),
    );
  }
}

// ============================================================
// TITRE SECTION
// ============================================================

class _DashboardSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DashboardSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATISTIQUES
// ============================================================

class _StatsGrid extends StatelessWidget {
  final int totalBus;
  final int direct;
  final int pause;
  final int lignes;

  const _StatsGrid({
    required this.totalBus,
    required this.direct,
    required this.pause,
    required this.lignes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.directions_bus_rounded,
            value: '$totalBus',
            label: 'Bus',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            icon: Icons.gps_fixed_rounded,
            value: '$direct',
            label: 'En direct',
            color: AppColors.busEnDirect,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            icon: Icons.pause_circle_outline_rounded,
            value: '$pause',
            label: 'En pause',
            color: AppColors.busArrete,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            icon: Icons.route_rounded,
            value: '$lignes',
            label: 'Lignes',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 103,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE8ECEA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CENTRE DE CONTRÔLE
// ============================================================

class _ControlCenter extends StatelessWidget {
  final List<Bus> buses;
  final int direct;
  final VoidCallback onCarte;

  const _ControlCenter({
    required this.buses,
    required this.direct,
    required this.onCarte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Décoration
          Positioned(
            right: -45,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(.07),
                  width: 25,
                ),
              ),
            ),
          ),

          Positioned(
            right: 22,
            bottom: 12,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 110,
              color: Colors.white.withOpacity(.06),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CENTRE DE CONTRÔLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Text(
                  '$direct bus actifs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Suivi GPS en temps réel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                ),

                const SizedBox(height: 13),

                SizedBox(
                  height: 35,
                  child: ElevatedButton.icon(
                    onPressed: onCarte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(
                      Icons.map_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'Ouvrir la carte',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
// ACTIONS RAPIDES
// ============================================================

class _QuickActions extends StatelessWidget {
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
          child: _QuickAction(
            icon: Icons.directions_bus_filled_rounded,
            title: 'Bus',
            subtitle: 'Ajouter',
            color: AppColors.primary,
            onTap: onAjouterBus,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _QuickAction(
            icon: Icons.route_rounded,
            title: 'Ligne',
            subtitle: 'Ajouter',
            color: AppColors.accent,
            onTap: onAjouterLigne,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Chauffeur',
            subtitle: 'Ajouter',
            color: AppColors.primary,
            onTap: onAjouterChauffeur,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _QuickAction(
            icon: Icons.map_rounded,
            title: 'Carte',
            subtitle: 'Flotte',
            color: AppColors.accent,
            onTap: onCarte,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 91,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE7EBE9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 17,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8.5,
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
// APERÇU RÉSEAU
// ============================================================

class _NetworkOverview extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;
  final int direct;
  final int pause;

  const _NetworkOverview({
    required this.buses,
    required this.lignes,
    required this.direct,
    required this.pause,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        buses.isEmpty ? 0 : ((direct / buses.length) * 100).round();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Column(
        children: [
          _NetworkRow(
            icon: Icons.gps_fixed_rounded,
            title: 'Couverture GPS',
            value: '$percentage%',
            progress: buses.isEmpty
                ? 0
                : direct / buses.length,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SmallNetworkInfo(
                  icon: Icons.directions_bus_rounded,
                  value: '$direct',
                  label: 'En circulation',
                  color: AppColors.busEnDirect,
                ),
              ),
              Expanded(
                child: _SmallNetworkInfo(
                  icon: Icons.pause_circle_outline_rounded,
                  value: '$pause',
                  label: 'En pause',
                  color: AppColors.busArrete,
                ),
              ),
              Expanded(
                child: _SmallNetworkInfo(
                  icon: Icons.route_rounded,
                  value: '${lignes.length}',
                  label: 'Lignes',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double progress;
  final Color color;

  const _NetworkRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 7,
            backgroundColor: const Color(0xFFE8ECEA),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _SmallNetworkInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SmallNetworkInfo({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 17,
          color: color,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTIVITÉ
// ============================================================

class _ActivityPanel extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;

  const _ActivityPanel({
    required this.buses,
    required this.lignes,
  });

  @override
  Widget build(BuildContext context) {
    final direct = buses.where((b) => b.enDirect).toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Column(
        children: [
          if (direct.isNotEmpty)
            _ActivityRow(
              icon: Icons.gps_fixed_rounded,
              color: AppColors.busEnDirect,
              title: '${direct.first.numero} est en circulation',
              subtitle:
                  '${direct.first.ligneNom ?? "Ligne non assignée"} • GPS actif',
            ),

          if (direct.isNotEmpty && buses.length > 1)
            const Divider(height: 1),

          if (buses.length > 1)
            _ActivityRow(
              icon: Icons.directions_bus_rounded,
              color: AppColors.primary,
              title: 'Bus ${buses[1].numero}',
              subtitle:
                  '${buses[1].ligneNom ?? "Aucune ligne"} • ${buses[1].statut}',
            ),

          if (lignes.isNotEmpty)
            const Divider(height: 1),

          if (lignes.isNotEmpty)
            _ActivityRow(
              icon: Icons.route_rounded,
              color: AppColors.accent,
              title: 'Réseau disponible',
              subtitle:
                  '${lignes.length} ligne(s) enregistrée(s)',
            ),

          if (direct.isEmpty && buses.isEmpty && lignes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Aucune activité pour le moment.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFB9C0BD),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INDICATEUR LIVE
// ============================================================

class _LiveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.busEnDirect.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.busEnDirect,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.busEnDirect,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BUS COMPACT
// ============================================================

class _CompactBusTile extends StatelessWidget {
  final Bus bus;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _CompactBusTile({
    required this.bus,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final direct = bus.enDirect;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: direct
                  ? AppColors.primary.withOpacity(.09)
                  : const Color(0xFFF0F2F1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: direct
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bus.numero,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    _StatusBadge(
                      direct: direct,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bus.ligneNom ?? 'Ligne non assignée',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 19,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'modifier') {
                onModifier();
              } else if (value == 'supprimer') {
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
                      size: 17,
                    ),
                    SizedBox(width: 8),
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
                      color: AppColors.danger,
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Supprimer',
                      style: TextStyle(
                        color: AppColors.danger,
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
// BADGE STATUT
// ============================================================

class _StatusBadge extends StatelessWidget {
  final bool direct;

  const _StatusBadge({
    required this.direct,
  });

  @override
  Widget build(BuildContext context) {
    final color = direct
        ? AppColors.busEnDirect
        : AppColors.busArrete;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            direct ? 'LIVE' : 'PAUSE',
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LIGNE COMPACTE
// ============================================================

class _CompactLineTile extends StatelessWidget {
  final Ligne ligne;

  const _CompactLineTile({
    required this.ligne,
  });

  Color _getColor() {
    try {
      return Color(
        int.parse(
          ligne.couleur.replaceFirst('#', '0xFF'),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                ligne.code,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ligne.depart ?? '?',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: color,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ligne.destination ?? '?',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ligne.busesCount ?? 0} bus',
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONGLET FLOTTE & RÉSEAU
// ============================================================

class _FleetView extends StatelessWidget {
  final List<Bus> buses;
  final List<Ligne> lignes;
  final TextEditingController controller;
  final String filtre;

  final void Function(String) onFilter;
  final VoidCallback onSearch;

  final void Function(Bus) onModifierBus;
  final void Function(Bus) onSupprimerBus;

  final void Function(Ligne) onModifierLigne;
  final void Function(Ligne) onSupprimerLigne;

  final VoidCallback onAjouterBus;
  final VoidCallback onAjouterLigne;

  const _FleetView({
    required this.buses,
    required this.lignes,
    required this.controller,
    required this.filtre,
    required this.onFilter,
    required this.onSearch,
    required this.onModifierBus,
    required this.onSupprimerBus,
    required this.onModifierLigne,
    required this.onSupprimerLigne,
    required this.onAjouterBus,
    required this.onAjouterLigne,
  });

  List<Bus> _filtered() {
    final query = controller.text.trim().toLowerCase();

    return buses.where((bus) {
      final search =
          query.isEmpty ||
          bus.numero.toLowerCase().contains(query) ||
          (bus.ligneNom ?? '').toLowerCase().contains(query) ||
          (bus.chauffeurNom ?? '').toLowerCase().contains(query);

      final filter = switch (filtre) {
        'En direct' => bus.enDirect,
        'En pause' => !bus.enDirect,
        _ => true,
      };

      return search && filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        100,
      ),
      children: [
        // ==================================================
        // RECHERCHE
        // ==================================================

        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFE2E7E4),
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => onSearch(),
            style: const TextStyle(
              fontSize: 11,
            ),
            decoration: const InputDecoration(
              hintText: 'Rechercher un bus ou une ligne...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),
        ),

        const SizedBox(height: 11),

        // ==================================================
        // FILTRES
        // ==================================================

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterButton(
                label: 'Tous',
                selected: filtre == 'Tous',
                onTap: () => onFilter('Tous'),
              ),
              const SizedBox(width: 7),
              _FilterButton(
                label: 'En direct',
                selected: filtre == 'En direct',
                onTap: () => onFilter('En direct'),
              ),
              const SizedBox(width: 7),
              _FilterButton(
                label: 'En pause',
                selected: filtre == 'En pause',
                onTap: () => onFilter('En pause'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 21),

        // ==================================================
        // FLOTTTE
        // ==================================================

        Row(
          children: [
            const Expanded(
              child: _DashboardSectionTitle(
                title: 'Flotte',
                subtitle: 'Bus enregistrés',
              ),
            ),
            _AddSmallButton(
              label: 'Ajouter',
              icon: Icons.add_rounded,
              onTap: onAjouterBus,
            ),
          ],
        ),

        const SizedBox(height: 11),

        if (filtered.isEmpty)
          const _EmptyPanel(
            icon: Icons.search_off_rounded,
            title: 'Aucun résultat',
            subtitle:
                'Aucun bus ne correspond à votre recherche.',
          )
        else
          ...filtered.map(
            (bus) => _CompactBusTile(
              bus: bus,
              onModifier: () => onModifierBus(bus),
              onSupprimer: () => onSupprimerBus(bus),
            ),
          ),

        const SizedBox(height: 22),

        // ==================================================
        // LIGNES
        // ==================================================

        Row(
          children: [
            const Expanded(
              child: _DashboardSectionTitle(
                title: 'Réseau',
                subtitle: 'Lignes configurées',
              ),
            ),
            _AddSmallButton(
              label: 'Ajouter',
              icon: Icons.add_rounded,
              onTap: onAjouterLigne,
            ),
          ],
        ),

        const SizedBox(height: 11),

        if (lignes.isEmpty)
          const _EmptyPanel(
            icon: Icons.route_outlined,
            title: 'Aucune ligne',
            subtitle: 'Ajoutez une ligne au réseau.',
          )
        else
          ...lignes.map(
            (ligne) => _ManageLineTile(
              ligne: ligne,
              onModifier: () => onModifierLigne(ligne),
              onSupprimer: () => onSupprimerLigne(ligne),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// FILTRE
// ============================================================

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFE2E7E4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PETIT BOUTON AJOUTER
// ============================================================

class _AddSmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AddSmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
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
// GESTION LIGNE
// ============================================================

class _ManageLineTile extends StatelessWidget {
  final Ligne ligne;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _ManageLineTile({
    required this.ligne,
    required this.onModifier,
    required this.onSupprimer,
  });

  Color _getColor() {
    try {
      return Color(
        int.parse(
          ligne.couleur.replaceFirst('#', '0xFF'),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                ligne.code,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.nom,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ligne.depart ?? '?'} → ${ligne.destination ?? '?'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${ligne.busesCount ?? 0}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'bus',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 19,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'modifier') {
                onModifier();
              } else {
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
                    color: AppColors.danger,
                  ),
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
// EMPTY
// ============================================================

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7EBE9),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}