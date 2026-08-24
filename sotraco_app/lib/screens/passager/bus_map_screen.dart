import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/bus.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';

class BusMapScreen extends StatefulWidget {
  final Bus bus;
  const BusMapScreen({super.key, required this.bus});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  final MapController _mapController = MapController();
  final RealtimeService _realtime = RealtimeService();
  late Bus _bus;
  DateTime? _derniereMaj;
  Timer? _horloge;
  bool _suivreAutomatiquement = true;
  bool _carteEstPrete = false;

  // Trace du trajet parcouru depuis le départ, façon "position en direct" Maps.
  final List<LatLng> _tracePoints = [];
  final List<LatLng> _positionsRecuesPendantHistorique = [];
  bool _historiqueEnChargement = true;

  @override
  void initState() {
    super.initState();
    _bus = widget.bus;
    _chargerHistorique();
    _chargerDernierePosition();
    _sabonnerAuBus();

    // Rafraîchit juste l'affichage "il y a X secondes"
    _horloge = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  /// Récupère les points GPS déjà enregistrés depuis le début du trajet en
  /// cours, pour afficher immédiatement la ligne parcourue jusqu'ici (au
  /// lieu de partir d'une trace vide au chargement de l'écran).
  Future<void> _chargerHistorique() async {
    try {
      final data = await ApiService.get('/buses/${_bus.id}/historique');
      final points = (data as List)
          .map((p) => LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()))
          .toList();
      if (!mounted) return;
      setState(() {
        _tracePoints
          ..clear()
          ..addAll(points);
        for (final point in _positionsRecuesPendantHistorique) {
          _ajouterPointSansDoublon(point);
        }
        _positionsRecuesPendantHistorique.clear();
        _historiqueEnChargement = false;
      });
    } catch (_) {
      // pas grave, la trace se construira au fil des positions reçues en direct
      if (mounted) {
        setState(() {
          for (final point in _positionsRecuesPendantHistorique) {
            _ajouterPointSansDoublon(point);
          }
          _positionsRecuesPendantHistorique.clear();
          _historiqueEnChargement = false;
        });
      }
    }
  }

  Future<void> _chargerDernierePosition() async {
    try {
      final data = await ApiService.get('/buses/${_bus.id}/position');
      setState(() {
        _bus.latitude = (data['latitude'] as num?)?.toDouble();
        _bus.longitude = (data['longitude'] as num?)?.toDouble();
        _bus.cap = (data['cap'] as num?)?.toDouble();
        _bus.vitesse = (data['vitesse'] as num?)?.toDouble();
        _bus.enDirect = data['en_direct'] ?? false;
        _derniereMaj = data['capture_a'] != null ? DateTime.tryParse(data['capture_a']) : null;
      });
      if (_bus.enDirect) _ajouterPointTrace(_bus.latitude, _bus.longitude);
      _centrerCarte();
    } catch (_) {
      // pas grave, on attend le websocket
    }
  }

  Future<void> _sabonnerAuBus() async {
    await _realtime.suivreBus(_bus.id, (data) {
      if (!mounted) return;
      setState(() {
        _bus.appliquerPosition(data);
        _derniereMaj = DateTime.now();
        if (!_bus.enDirect) {
          _tracePoints.clear();
          _positionsRecuesPendantHistorique.clear();
        }
      });
      if (_bus.enDirect) _ajouterPointTrace(_bus.latitude, _bus.longitude);
      _centrerCarte();
    });
  }

  void _ajouterPointTrace(double? lat, double? lng) {
    if (lat == null || lng == null) return;
    final point = LatLng(lat, lng);
    if (_historiqueEnChargement) {
      _positionsRecuesPendantHistorique.add(point);
      return;
    }
    setState(() => _ajouterPointSansDoublon(point));
  }

  void _ajouterPointSansDoublon(LatLng point) {
    // Évite d'empiler des points identiques si le bus est à l'arrêt.
    if (_tracePoints.isNotEmpty) {
      final dernier = _tracePoints.last;
      final distance = const Distance().as(LengthUnit.Meter, dernier, point);
      if (distance < 10) return;
    }
    _tracePoints.add(point);
  }

  void _centrerCarte() {
    if (_bus.latitude == null || _bus.longitude == null) return;
    if (!_suivreAutomatiquement || !_carteEstPrete) return;
    _mapController.move(LatLng(_bus.latitude!, _bus.longitude!), _mapController.camera.zoom);
  }

  String get _texteDerniereMaj {
    if (_derniereMaj == null) return 'Position inconnue';
    final secondes = DateTime.now().difference(_derniereMaj!).inSeconds;
    if (secondes < 10) return 'À l\'instant';
    if (secondes < 60) return 'Il y a $secondes s';
    return 'Il y a ${(secondes / 60).floor()} min';
  }

  @override
  void dispose() {
    _horloge?.cancel();
    _realtime.arreterSuivi(_bus.id);
    _realtime.deconnecter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = (_bus.latitude != null && _bus.longitude != null)
        ? LatLng(_bus.latitude!, _bus.longitude!)
        : const LatLng(12.3714, -1.5197); // centre de Ouagadougou par défaut

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: position,
              initialZoom: 15,
              onMapReady: () => setState(() => _carteEstPrete = true),
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) setState(() => _suivreAutomatiquement = false);
              },
            ),
            children: [
              // Fond de carte OpenStreetMap (gratuit, sans clé API)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'bf.sotraco.app',
              ),
              // Trace du trajet parcouru depuis le départ (grandit en direct)
              if (_tracePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _tracePoints,
                      strokeWidth: 5,
                      color: AppColors.primary.withOpacity(0.85),
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              // Marqueur du point de départ
              if (_tracePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _tracePoints.first,
                      width: 18,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              // Marqueur du bus (position actuelle, en mouvement)
              if (_bus.latitude != null && _bus.longitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 46,
                      height: 46,
                      child: Transform.rotate(
                        angle: (_bus.cap ?? 0) * (3.1415926535 / 180),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Attribution OpenStreetMap (obligatoire, licence ODbL)
          const Positioned(
            bottom: 4,
            left: 4,
            child: _AttributionOSM(),
          ),
          // Bouton retour
          Positioned(
            top: 48,
            left: 16,
            child: _BoutonRond(
              icone: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // Bouton recentrer
          Positioned(
            bottom: 210,
            right: 16,
            child: _BoutonRond(
              icone: Icons.my_location_rounded,
              onTap: () {
                setState(() => _suivreAutomatiquement = true);
                _centrerCarte();
              },
            ),
          ),
          // Panneau d'information en bas, façon "partage de position en direct"
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bus.numero,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _bus.ligneNom ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            if (_bus.sens != null)
                              Text(
                                _bus.sens == 'aller' ? 'Aller' : 'Retour',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                      _PastilleStatut(enDirect: _bus.enDirect),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoMini(icone: Icons.speed_rounded, label: 'Vitesse', valeur: '${_bus.vitesse?.toStringAsFixed(0) ?? '--'} km/h'),
                      const SizedBox(width: 20),
                      _InfoMini(icone: Icons.update_rounded, label: 'Mise à jour', valeur: _texteDerniereMaj),
                    ],
                  ),
                  if (!_bus.enDirect) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Ce bus ne partage pas sa position pour le moment.",
                              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                            ),
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
    );
  }
}

class _AttributionOSM extends StatelessWidget {
  const _AttributionOSM();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: Colors.white70,
      child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Colors.black87)),
    );
  }
}

class _PastilleStatut extends StatelessWidget {
  final bool enDirect;
  const _PastilleStatut({required this.enDirect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: enDirect ? AppColors.busEnDirect : AppColors.busArrete, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              enDirect ? 'En direct' : 'Hors ligne',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: enDirect ? AppColors.busEnDirect : AppColors.busArrete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMini extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _InfoMini({required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(valeur, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _BoutonRond({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icone, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
