import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/bus.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';

class FleetMapScreen extends StatefulWidget {
  const FleetMapScreen({super.key});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  // --- Logique de suivi multi-bus : INCHANGÉE, ne pas modifier ---
  final MapController _mapController = MapController();
  final RealtimeService _realtime = RealtimeService();
  final Map<int, Bus> _buses = {};
  final Map<int, List<LatLng>> _traces = {};
  final Map<int, List<LatLng>> _routes = {};
  Timer? _rafraichissement;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerBusEnMouvement();
    _rafraichissement = Timer.periodic(const Duration(seconds: 20), (_) => _chargerBusEnMouvement());
  }

  Future<void> _chargerBusEnMouvement() async {
    try {
      final data = await ApiService.get('/buses?en_marche=1');
      final items = (data as List).map((item) => Map<String, dynamic>.from(item)).toList();
      final busActifs = items.map(Bus.fromJson).where((bus) => bus.enDirect).toList();
      final actifs = busActifs.map((bus) => bus.id).toSet();

      for (final bus in busActifs) {
        _buses[bus.id] = bus;
        _routes[bus.id] = _extraireRoute(items.firstWhere((item) => item['id'] == bus.id));
        await _chargerTrace(bus);
        await _realtime.suivreBus(bus.id, (position) {
          if (!mounted) return;
          final cible = _buses[bus.id];
          if (cible == null) return;
          cible.appliquerPosition(position);
          if (!cible.enDirect) {
            _buses.remove(bus.id);
            _traces.remove(bus.id);
            _routes.remove(bus.id);
            setState(() {});
            return;
          }
          _ajouterPoint(bus.id, cible.latitude, cible.longitude);
          setState(() {});
        });
      }

      final anciens = _buses.keys.where((id) => !actifs.contains(id)).toList();
      for (final id in anciens) {
        await _realtime.arreterSuivi(id);
        _buses.remove(id);
        _traces.remove(id);
        _routes.remove(id);
      }
      if (mounted) setState(() => _chargement = false);
    } on ApiException catch (error) {
      if (mounted) setState(() { _erreur = error.message; _chargement = false; });
    } catch (error) {
      if (mounted) setState(() { _erreur = error.toString(); _chargement = false; });
    }
  }

  List<LatLng> _extraireRoute(Map<String, dynamic> json) {
    final arrets = json['ligne']?['arrets'];
    if (arrets is! List) return [];
    final route = arrets
        .map((arret) {
          final latitude = (arret['latitude'] as num?)?.toDouble();
          final longitude = (arret['longitude'] as num?)?.toDouble();
          return latitude != null && longitude != null ? LatLng(latitude, longitude) : null;
        })
        .whereType<LatLng>()
        .toList();
    return json['trajet_actif']?['sens'] == 'retour' ? route.reversed.toList() : route;
  }

  Future<void> _chargerTrace(Bus bus) async {
    try {
      final data = await ApiService.get('/buses/${bus.id}/historique');
      _traces[bus.id] = (data as List).map((point) => LatLng((point['latitude'] as num).toDouble(), (point['longitude'] as num).toDouble())).toList();
    } catch (_) {
      _traces.putIfAbsent(bus.id, () => []);
    }
    _ajouterPoint(bus.id, bus.latitude, bus.longitude);
  }

  void _ajouterPoint(int busId, double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return;
    final point = LatLng(latitude, longitude);
    final trace = _traces.putIfAbsent(busId, () => []);
    if (trace.isNotEmpty && const Distance().as(LengthUnit.Meter, trace.last, point) < 10) return;
    trace.add(point);
  }

  static const List<Color> _palette = [AppColors.primary, Color(0xFF2F7DE1), Color(0xFFF2A104), Color(0xFF7A4EAB), Color(0xFFE1425A), Color(0xFF17A2A2)];

  Color _couleurPour(int ligneId) => _palette[ligneId.abs() % _palette.length];
  // --- Fin logique inchangée ---

  @override
  void dispose() {
    _rafraichissement?.cancel();
    _realtime.deconnecter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buses.values.where((bus) => bus.latitude != null && bus.longitude != null).map((bus) {
      final couleur = _couleurPour(bus.ligneId ?? bus.id);
      return Marker(
        point: LatLng(bus.latitude!, bus.longitude!),
        width: 74,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: AppShadows.soft),
              child: Text(bus.numero, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Transform.rotate(
              angle: (bus.cap ?? 0) * math.pi / 180,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: couleur, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]),
                child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      );
    }).toList();

    final polylines = <Polyline>[];
    for (final bus in _buses.values) {
      final couleur = _couleurPour(bus.ligneId ?? bus.id);
      final route = _routes[bus.id] ?? [];
      if (route.length > 1) {
        polylines.add(Polyline(points: route, strokeWidth: 3, color: couleur.withOpacity(0.25), borderColor: Colors.white, borderStrokeWidth: 1));
      }
      final trace = _traces[bus.id] ?? [];
      if (trace.length > 1) {
        polylines.add(Polyline(points: trace, strokeWidth: 10, color: couleur.withOpacity(0.18)));
        polylines.add(Polyline(points: trace, strokeWidth: 5, color: couleur, borderColor: Colors.white, borderStrokeWidth: 1.5));
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: LatLng(12.3714, -1.5197), initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'bf.sotraco.app',
                maxZoom: 20,
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 48,
            left: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _chargerBusEnMouvement,
                child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.refresh_rounded, color: AppColors.textPrimary)),
              ),
            ),
          ),
          if (_erreur != null)
            Positioned(
              top: 104,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
                child: Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.lifted),
              child: _chargement
                  ? const Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)), SizedBox(width: 14), Text('Chargement des bus en mouvement...')])
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.timeline_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_buses.length} bus en circulation', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              const Text('Les traits épais montrent le trajet déjà parcouru.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
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
