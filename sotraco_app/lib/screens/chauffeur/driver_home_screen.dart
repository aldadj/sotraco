import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../splash_screen.dart';
import '../passager/home_screen.dart';
import 'start_trip_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  bool _partageActif = false;
  bool _chargement = false;
  String? _erreur;
  Map<String, dynamic>? _trajetActif;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _chargerTrajetActif();
  }

  Future<void> _chargerTrajetActif() async {
    try {
      final data = await ApiService.get('/chauffeur/trajet-actif');
      if (mounted) {
        setState(() {
          _trajetActif = data['trajet_actif'] == true ? Map<String, dynamic>.from(data['trajet']) : null;
          _partageActif = _trajetActif?['bus']?['en_marche'] == true;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _erreur = error.message);
    }
  }

  Future<void> _preparerTrajet() async {
    final demarre = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const StartTripScreen()));
    if (demarre != true || !mounted) return;
    await _chargerTrajetActif();
    if (_trajetActif != null) await _basculerPartage();
  }

  Future<void> _basculerPartage() async {
    if (_trajetActif == null) {
      await _preparerTrajet();
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    if (_partageActif) {
      await _locationService.arreterPartage();
      setState(() {
        _partageActif = false;
        _chargement = false;
      });
      return;
    }

    final succes = await _locationService.demarrerPartage(onErreur: (msg) => setState(() => _erreur = msg));
    setState(() {
      _partageActif = succes;
      _chargement = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 116,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Espace chauffeur', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
            ),
            actions: [
              IconButton(
                tooltip: 'Suivre un bus',
                icon: const Icon(Icons.directions_bus_filled_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PassengerHomeScreen())),
              ),
              IconButton(
                tooltip: 'Déconnexion',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await _locationService.arreterPartage();
                  await auth.deconnecter();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  Text('Bonjour ${auth.user?.name.split(' ').first ?? ''} 👋', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    _trajetActif == null
                        ? 'Choisis ton bus et ta ligne pour commencer.'
                        : _partageActif
                            ? 'Ta position est visible en direct par les passagers.'
                            : 'Active le partage pour que les passagers puissent te suivre.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const Spacer(),
                  if (_trajetActif != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bus ${_trajetActif!['bus']?['numero'] ?? '--'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              Text('${_trajetActif!['ligne']?['nom'] ?? '--'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            _trajetActif!['sens'] == 'aller' ? 'Aller' : 'Retour',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: _chargement ? null : _basculerPartage,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(alignment: Alignment.center, children: [
                        if (_partageActif)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1 + _pulseController.value * 0.35;
                              final opacity = (1 - _pulseController.value).clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity * 0.4,
                                  child: Container(width: 200, height: 200, decoration: const BoxDecoration(color: AppColors.busEnDirect, shape: BoxShape.circle)),
                                ),
                              );
                            },
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _partageActif ? const LinearGradient(colors: [AppColors.danger, Color(0xFFB92E44)]) : AppColors.heroGradient,
                            boxShadow: [BoxShadow(color: (_partageActif ? AppColors.danger : AppColors.primary).withOpacity(0.35), blurRadius: 30, spreadRadius: 4)],
                          ),
                          child: Center(
                            child: _chargement
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_partageActif ? Icons.stop_rounded : Icons.share_location_rounded, color: Colors.white, size: 46),
                                      const SizedBox(height: 8),
                                      Text(
                                        _trajetActif == null ? 'Choisir le\ntrajet' : (_partageActif ? 'Arrêter le\npartage' : 'Partager ma\nposition'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_erreur != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_erreur!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                    ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text("Garde l'application ouverte pendant ton service pour un suivi continu.", style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
