import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Gère la localisation GPS du chauffeur et l'envoi périodique au backend.
/// C'est ce service qui est activé quand le chauffeur clique sur
/// "Partager ma position" dans l'app.
class LocationService {
  StreamSubscription<Position>? _subscription;
  bool get estActif => _subscription != null;

  Future<bool> _verifierPermissions() async {
    bool serviceActive = await Geolocator.isLocationServiceEnabled();
    if (!serviceActive) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Démarre le partage : écoute le GPS et envoie chaque nouvelle position
  /// au backend (qui la diffuse ensuite en temps réel aux passagers).
  Future<bool> demarrerPartage({void Function(String erreur)? onErreur}) async {
    final autorise = await _verifierPermissions();
    if (!autorise) {
      onErreur?.call("La localisation doit être activée pour partager ta position.");
      return false;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // envoie une mise à jour tous les 10 mètres minimum
    );

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) async {
        try {
          await ApiService.post('/chauffeur/position', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'cap': position.heading,
            'vitesse': position.speed * 3.6, // m/s -> km/h
          });
        } catch (e) {
          onErreur?.call(e.toString());
        }
      },
      onError: (e) => onErreur?.call(e.toString()),
    );

    return true;
  }

  Future<void> arreterPartage() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await ApiService.post('/chauffeur/arreter-partage', {});
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
  }
}
