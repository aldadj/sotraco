import 'dart:async';
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
        final busActifs = items
          .map(Bus.fromJson)
          .where((bus) => bus.enDirect)
          .toList();
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
      if (mounted) {
        setState(() => _chargement = false);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _erreur = error.message;
          _chargement = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _erreur = error.toString();
          _chargement = false;
        });
      }
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
      _traces[bus.id] = (data as List)
          .map((point) => LatLng((point['latitude'] as num).toDouble(), (point['longitude'] as num).toDouble()))
          .toList();
    } catch (_) {
      _traces.putIfAbsent(bus.id, () => []);
    }
    _ajouterPoint(bus.id, bus.latitude, bus.longitude);
  }

  void _ajouterPoint(int busId, double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return;
    final point = LatLng(latitude, longitude);
    final trace = _traces.putIfAbsent(busId, () => []);
    if (trace.isNotEmpty && const Distance().as(LengthUnit.Meter, trace.last, point) < 3) return;
    trace.add(point);
  }

  Color _couleurPour(int ligneId) {
    const couleurs = [AppColors.primary, Colors.indigo, Colors.deepOrange, Colors.teal, Colors.pink, Colors.blueGrey];
    return couleurs[ligneId.abs() % couleurs.length];
  }

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
        width: 62,
        height: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              color: Colors.white,
              child: Text(bus.numero, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Transform.rotate(
              angle: (bus.cap ?? 0) * 3.1415926535 / 180,
              child: Icon(Icons.directions_bus_filled_rounded, color: couleur, size: 30),
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
        polylines.add(Polyline(points: trace, strokeWidth: 6, color: couleur, borderColor: Colors.white, borderStrokeWidth: 1.5));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte générale des bus'),
        actions: [
          IconButton(onPressed: _chargerBusEnMouvement, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: LatLng(12.3714, -1.5197), initialZoom: 12),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'bf.sotraco.app'),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _chargement
                    ? const Row(children: [CircularProgressIndicator(), SizedBox(width: 12), Text('Chargement des bus en mouvement...')])
                    : Text('${_buses.length} bus en mouvement • Les traits épais montrent le parcours déjà effectué.'),
              ),
            ),
          ),
          if (_erreur != null)
            Positioned(top: 12, left: 16, right: 16, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_erreur!, style: const TextStyle(color: AppColors.danger))))),
        ],
      ),
    );
  }
}
