import 'dart:async';
import 'dart:math' as math;
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

class _BusMapScreenState extends State<BusMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final RealtimeService _realtime = RealtimeService();
  late Bus _bus;
  DateTime? _derniereMaj;
  Timer? _horloge;
  bool _suivreAutomatiquement = true;
  bool _carteEstPrete = false;

  // --- Logique de tracé GPS : INCHANGÉE, ne pas modifier ---
  final List<LatLng> _tracePoints = [];
  final List<LatLng> _positionsRecuesPendantHistorique = [];
  bool _historiqueEnChargement = true;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bus = widget.bus;
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _chargerHistorique();
    _chargerDernierePosition();
    _sabonnerAuBus();
    _horloge = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

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
    } catch (_) {}
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
  // --- Fin logique de tracé GPS ---

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
    _pulseController.dispose();
    _realtime.arreterSuivi(_bus.id);
    _realtime.deconnecter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = (_bus.latitude != null && _bus.longitude != null)
        ? LatLng(_bus.latitude!, _bus.longitude!)
        : const LatLng(12.3714, -1.5197);

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
              // Fond de carte "Voyager" (CARTO) : rendu plus épuré et pro
              // qu'un rendu OSM brut, gratuit, sans clé API.
             TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'bf.sotraco.app',
                maxZoom: 19,
              ),
              // Effet de "lueur" sous le tracé : deux polylignes superposées.
              if (_tracePoints.length > 1) ...[
                PolylineLayer(polylines: [
                  Polyline(points: _tracePoints, strokeWidth: 11, color: AppColors.primary.withOpacity(0.18)),
                ]),
                PolylineLayer(polylines: [
                  Polyline(
                    points: _tracePoints,
                    strokeWidth: 5,
                    color: AppColors.primary,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.6,
                  ),
                ]),
              ],
              if (_tracePoints.isNotEmpty)
                MarkerLayer(markers: [
                  Marker(
                    point: _tracePoints.first,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.trip_origin_rounded, size: 10, color: AppColors.primary),
                    ),
                  ),
                ]),
              if (_bus.latitude != null && _bus.longitude != null)
                MarkerLayer(markers: [
                  Marker(
                    point: position,
                    width: 76,
                    height: 76,
                    child: _BusMarker(cap: _bus.cap ?? 0, enDirect: _bus.enDirect, pulse: _pulseController),
                  ),
                ]),
            ],
          ),
          const Positioned(bottom: 4, left: 4, child: _AttributionOSM()),
          Positioned(
            top: 48,
            left: 16,
            child: _BoutonRond(icone: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: _BusPill(numero: _bus.numero, sens: _bus.sens),
          ),
          Positioned(
            bottom: 216,
            right: 16,
            child: _BoutonRond(
              icone: Icons.my_location_rounded,
              onTap: () {
                setState(() => _suivreAutomatiquement = true);
                _centrerCarte();
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _InfoPanel(bus: _bus, texteDerniereMaj: _texteDerniereMaj),
          ),
        ],
      ),
    );
  }
}

class _BusMarker extends StatelessWidget {
  final double cap;
  final bool enDirect;
  final AnimationController pulse;

  const _BusMarker({required this.cap, required this.enDirect, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (enDirect)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final scale = 1 + pulse.value * 0.9;
                final opacity = (1 - pulse.value).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity * 0.5,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.busEnDirect, shape: BoxShape.circle),
                    ),
                  ),
                );
              },
            ),
          Transform.rotate(
            angle: cap * (math.pi / 180),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: enDirect ? AppColors.heroGradient : null,
                color: enDirect ? null : AppColors.busArrete,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusPill extends StatelessWidget {
  final String numero;
  final String? sens;
  const _BusPill({required this.numero, this.sens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Text(numero, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        if (sens != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(sens == 'aller' ? Icons.north_east_rounded : Icons.south_west_rounded, size: 13, color: AppColors.primary),
            const SizedBox(width: 3),
            Text(sens == 'aller' ? 'Aller' : 'Retour', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
      ]),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final Bus bus;
  final String texteDerniereMaj;
  const _InfoPanel({required this.bus, required this.texteDerniereMaj});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.numero, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(bus.ligneNom ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              _PastilleStatut(enDirect: bus.enDirect),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [
            _InfoMini(icone: Icons.speed_rounded, label: 'Vitesse', valeur: '${bus.vitesse?.toStringAsFixed(0) ?? '--'} km/h'),
            const SizedBox(width: 12),
            _InfoMini(icone: Icons.update_rounded, label: 'Mise à jour', valeur: texteDerniereMaj),
          ]),
          if (!bus.enDirect) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text("Ce bus ne partage pas sa position pour le moment.", style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
              ]),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      color: Colors.white70,
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(
          fontSize: 9,
          color: Colors.black87,
        ),
      ),
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
      decoration: BoxDecoration(color: (enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: enDirect ? AppColors.busEnDirect : AppColors.busArrete, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            enDirect ? 'En direct' : 'Hors ligne',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: enDirect ? AppColors.busEnDirect : AppColors.busArrete),
          ),
        ),
      ]),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icone, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                Text(valeur, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ]),
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
        child: Padding(padding: const EdgeInsets.all(12), child: Icon(icone, color: AppColors.textPrimary)),
      ),
    );
  }
}
