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

  @override
  void initState() {
    super.initState();
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
    final demarre = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StartTripScreen()),
    );
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

    final succes = await _locationService.demarrerPartage(
      onErreur: (msg) => setState(() => _erreur = msg),
    );
    setState(() {
      _partageActif = succes;
      _chargement = false;
    });
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace chauffeur'),
        actions: [
          IconButton(
            tooltip: 'Suivre un bus',
            icon: const Icon(Icons.directions_bus_filled_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _locationService.arreterPartage();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text('Bonjour ${auth.user?.name.split(' ').first ?? ''} 👋',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _trajetActif == null
                    ? 'Choisis ton bus et ta ligne pour commencer.'
                    : _partageActif
                    ? 'Ta position est visible en direct par les passagers.'
                    : 'Active le partage pour que les passagers puissent te suivre.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (_trajetActif != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'Bus ${_trajetActif!['bus']?['numero'] ?? '--'}  •  ${_trajetActif!['ligne']?['nom'] ?? '--'}  •  ${_trajetActif!['sens'] == 'aller' ? 'Aller' : 'Retour'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _chargement ? null : _basculerPartage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _partageActif ? AppColors.danger : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_partageActif ? AppColors.danger : AppColors.primary).withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _chargement
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _partageActif ? Icons.stop_rounded : Icons.share_location_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _trajetActif == null
                                  ? 'Choisir le\ntrajet'
                                  : _partageActif ? 'Arrêter le\npartage' : 'Partager ma\nposition',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_erreur != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_erreur!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Garde l'application ouverte pendant ton service pour un suivi continu.",
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
