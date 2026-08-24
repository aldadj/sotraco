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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChauffeurFormScreen()),
    );
  }

  Future<void> _confirmerSuppressionBus(Bus bus) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce bus ?'),
        content: Text('${bus.numero} sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
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
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette ligne ?'),
        content: Text('${ligne.nom} sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await AdminService.supprimerLigne(ligne.id);
      _rafraichir();
    } on ApiException catch (e) {
      if (mounted) _afficherErreur(e.message);
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final busProvider = context.watch<BusProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Flotte'),
            Tab(text: 'Lignes'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Voir tous les bus en mouvement',
            icon: const Icon(Icons.map_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FleetMapScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Enregistrer un chauffeur',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _ouvrirFormulaireChauffeur,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.deconnecter();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
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
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: _tabController.index == 0 ? () => _ouvrirFormulaireBus() : () => _ouvrirFormulaireLigne(),
          icon: const Icon(Icons.add_rounded),
          label: Text(_tabController.index == 0 ? 'Ajouter un bus' : 'Ajouter une ligne'),
        ),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(titre: 'Bus au total', valeur: '${buses.length}', icone: Icons.directions_bus_filled_rounded)),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(titre: 'En circulation', valeur: '$enDirect', icone: Icons.gps_fixed_rounded, couleur: AppColors.busEnDirect),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (buses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Aucun bus pour le moment', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...buses.map((bus) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (bus.enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12),
                      child: Icon(Icons.directions_bus_rounded, color: bus.enDirect ? AppColors.busEnDirect : AppColors.busArrete),
                    ),
                    title: Text(bus.numero, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${bus.ligneNom ?? "Non assigné"} • ${bus.chauffeurNom ?? "Sans chauffeur"} • ${bus.statut}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (choix) {
                        if (choix == 'modifier') onModifier(bus);
                        if (choix == 'supprimer') onSupprimer(bus);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                        PopupMenuItem(value: 'supprimer', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ),
                )),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
        children: [
          if (lignes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Aucune ligne pour le moment', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...lignes.map((ligne) {
              final couleur = Color(int.parse(ligne.couleur.replaceFirst('#', '0xFF')));
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: couleur.withOpacity(0.15), child: Icon(Icons.alt_route_rounded, color: couleur)),
                  title: Text('${ligne.code} — ${ligne.nom}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${ligne.depart ?? "?"} → ${ligne.destination ?? "?"} • ${ligne.busesCount ?? 0} bus'),
                  trailing: PopupMenuButton<String>(
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

class _StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({required this.titre, required this.valeur, required this.icone, this.couleur = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: couleur),
            ),
            const SizedBox(height: 10),
            Text(valeur, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
