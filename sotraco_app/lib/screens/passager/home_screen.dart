import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bus_card.dart';
import '../splash_screen.dart';
import 'bus_map_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int? _ligneSelectionnee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusProvider>();
      provider.chargerLignes();
      provider.chargerBuses();
    });
  }

  Future<void> _rafraichir() async {
    final provider = context.read<BusProvider>();
    await Future.wait([
      provider.chargerLignes(),
      provider.chargerBuses(ligneId: _ligneSelectionnee),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final auth = context.watch<AuthProvider>();
    final busEnMarche = busProvider.buses.where((b) => b.enDirect).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeaderCard(nom: auth.user?.name.split(' ').first ?? '', busEnMarche: busEnMarche, onLogout: () async {
              await auth.deconnecter();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
            })),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _ChipLigne(
                      label: 'Toutes les lignes',
                      selectionnee: _ligneSelectionnee == null,
                      onTap: () {
                        setState(() => _ligneSelectionnee = null);
                        context.read<BusProvider>().chargerBuses();
                      },
                    ),
                    ...busProvider.lignes.map((ligne) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _ChipLigne(
                            label: ligne.nom,
                            selectionnee: _ligneSelectionnee == ligne.id,
                            onTap: () {
                              setState(() => _ligneSelectionnee = ligne.id);
                              context.read<BusProvider>().chargerBuses(ligneId: ligne.id);
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (busProvider.chargement)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (busProvider.buses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
                        child: const Icon(Icons.directions_bus_outlined, size: 34, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Text('Aucun bus sur cette ligne pour le moment', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bus = busProvider.buses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BusCard(bus: bus, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BusMapScreen(bus: bus)))),
                      );
                    },
                    childCount: busProvider.buses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String nom;
  final int busEnMarche;
  final VoidCallback onLogout;

  const _HeaderCard({required this.nom, required this.busEnMarche, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -20, child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour $nom 👋', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('$busEnMarche bus en circulation en ce moment', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                    ]),
                  ],
                ),
              ),
              IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLigne extends StatelessWidget {
  final String label;
  final bool selectionnee;
  final VoidCallback onTap;

  const _ChipLigne({required this.label, required this.selectionnee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectionnee,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selectionnee ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selectionnee ? AppColors.primary : Colors.grey.shade300)),
    );
  }
}
