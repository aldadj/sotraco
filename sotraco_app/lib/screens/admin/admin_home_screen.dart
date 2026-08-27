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

/// Tableau de bord admin : gestion complète du parc (bus) et des lignes,
/// avec ajout / modification / suppression. Ces droits sont réservés à
/// l'admin — le chauffeur ne peut que partager sa position (voir
/// PositionController côté backend, protégé par le middleware "role").
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _rafraichir());
  }

  Future<void> _rafraichir() async {
    final provider = context.read<BusProvider>();
    await Future.wait([provider.chargerLignes(), provider.chargerBuses()]);
    if (mounted && provider.erreur != null) _afficherErreur(provider.erreur!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _ouvrirFormulaireBus({Bus? bus}) async {
    final busProvider = context.read<BusProvider>();
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BusFormScreen(bus: bus, lignes: busProvider.lignes)),
    );
    if (resultat == true) await _rafraichir();
  }

  Future<void> _ouvrirFormulaireLigne({Ligne? ligne}) async {
    final resultat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LigneFormScreen(ligne: ligne)),
    );
    if (resultat == true) await _rafraichir();
  }

  Future<void> _ouvrirFormulaireChauffeur() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChauffeurFormScreen()));
  }

  Future<void> _confirmerSuppressionBus(Bus bus) async {
    final confirme = await _confirmer(
      titre: 'Supprimer ce bus ?',
      message: '${bus.numero} sera définitivement supprimé.',
    );
    if (confirme != true) return;
    try {
      await AdminService.supprimerBus(bus.id);
      _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  Future<void> _confirmerSuppressionLigne(Ligne ligne) async {
    final confirme = await _confirmer(
      titre: 'Supprimer cette ligne ?',
      message: '${ligne.nom} sera définitivement supprimée.',
    );
    if (confirme != true) return;
    try {
      await AdminService.supprimerLigne(ligne.id);
      _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  Future<bool?> _confirmer({required String titre, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final busProvider = context.watch<BusProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 128,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 66),
              title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.w800)),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
            ),
            actions: [
              IconButton(
                tooltip: 'Voir tous les bus en mouvement',
                icon: const Icon(Icons.map_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FleetMapScreen())),
              ),
              IconButton(
                tooltip: 'Enregistrer un chauffeur',
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: _ouvrirFormulaireChauffeur,
              ),
              IconButton(
                tooltip: 'Déconnexion',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await auth.deconnecter();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Flotte'),
                      Tab(text: 'Lignes'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OngletFlotte(
              buses: busProvider.buses,
              onModifier: (bus) => _ouvrirFormulaireBus(bus: bus),
              onSupprimer: _confirmerSuppressionBus,
              onRafraichir: _rafraichir,
            ),
            _OngletLignes(
              lignes: busProvider.lignes,
              onModifier: (ligne) => _ouvrirFormulaireLigne(ligne: ligne),
              onSupprimer: _confirmerSuppressionLigne,
              onRafraichir: _rafraichir,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: _tabController.index == 0 ? () => _ouvrirFormulaireBus() : () => _ouvrirFormulaireLigne(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'Ajouter un bus' : 'Ajouter une ligne'),
      ),
    );
  }
}

class _OngletFlotte extends StatelessWidget {
  final List<Bus> buses;
  final void Function(Bus) onModifier;
  final void Function(Bus) onSupprimer;
  final Future<void> Function() onRafraichir;

  const _OngletFlotte({required this.buses, required this.onModifier, required this.onSupprimer, required this.onRafraichir});

  @override
  Widget build(BuildContext context) {
    final enDirect = buses.where((b) => b.enDirect).length;

    return RefreshIndicator(
      onRefresh: onRafraichir,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(titre: 'Bus au total', valeur: '${buses.length}', icone: Icons.directions_bus_filled_rounded)),
              const SizedBox(width: 14),
              Expanded(child: _StatCard(titre: 'En circulation', valeur: '$enDirect', icone: Icons.gps_fixed_rounded, couleur: AppColors.busEnDirect)),
            ],
          ),
          const SizedBox(height: 22),
          if (buses.isEmpty)
            const _EtatVide(icone: Icons.directions_bus_outlined, texte: 'Aucun bus pour le moment')
          else
            ...buses.map((bus) => _BusAdminTile(bus: bus, onModifier: () => onModifier(bus), onSupprimer: () => onSupprimer(bus))),
        ],
      ),
    );
  }
}

class _BusAdminTile extends StatelessWidget {
  final Bus bus;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _BusAdminTile({required this.bus, required this.onModifier, required this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: bus.enDirect ? AppColors.heroGradient : null,
            color: bus.enDirect ? null : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.directions_bus_rounded, color: bus.enDirect ? Colors.white : AppColors.busArrete),
        ),
        title: Text(bus.numero, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${bus.ligneNom ?? "Non assigné"} • ${bus.chauffeurNom ?? "Sans chauffeur"} • ${bus.statut}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (choix) {
            if (choix == 'modifier') onModifier();
            if (choix == 'supprimer') onSupprimer();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'modifier', child: Text('Modifier')),
            PopupMenuItem(value: 'supprimer', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
          ],
        ),
      ),
    );
  }
}

class _OngletLignes extends StatelessWidget {
  final List<Ligne> lignes;
  final void Function(Ligne) onModifier;
  final void Function(Ligne) onSupprimer;
  final Future<void> Function() onRafraichir;

  const _OngletLignes({required this.lignes, required this.onModifier, required this.onSupprimer, required this.onRafraichir});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRafraichir,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          if (lignes.isEmpty)
            const _EtatVide(icone: Icons.alt_route_rounded, texte: 'Aucune ligne pour le moment')
          else
            ...lignes.map((ligne) {
              final couleur = Color(int.parse(ligne.couleur.replaceFirst('#', '0xFF')));
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: couleur.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.alt_route_rounded, color: couleur),
                  ),
                  title: Text('${ligne.code} — ${ligne.nom}', style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${ligne.depart ?? "?"} → ${ligne.destination ?? "?"} • ${ligne.busesCount ?? 0} bus'),
                  trailing: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (choix) {
                      if (choix == 'modifier') onModifier(ligne);
                      if (choix == 'supprimer') onSupprimer(ligne);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                      PopupMenuItem(value: 'supprimer', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _EtatVide({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle), child: Icon(icone, size: 32, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Text(texte, style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({required this.titre, required this.valeur, required this.icone, this.couleur = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icone, color: couleur),
          ),
          const SizedBox(height: 12),
          Text(valeur, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
