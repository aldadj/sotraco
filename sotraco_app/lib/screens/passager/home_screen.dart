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
      appBar: AppBar(
        title: const Text('SOTRACO'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour ${auth.user?.name.split(' ').first ?? ''} 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$busEnMarche bus en circulation en ce moment',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
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
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (busProvider.chargement)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (busProvider.buses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus_outlined, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
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
                        child: BusCard(
                          bus: bus,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => BusMapScreen(bus: bus)),
                          ),
                        ),
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
      labelStyle: TextStyle(
        color: selectionnee ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selectionnee ? AppColors.primary : Colors.grey.shade300),
      ),
    );
  }
}
