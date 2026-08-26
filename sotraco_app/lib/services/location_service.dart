import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Gère la localisation GPS du chauffeur et l'envoi périodique au backend.
/// C'est ce service qui est activé quand le chauffeur clique sur
/// "Partager ma position" dans l'app.
class LocationService {
  StreamSubscription<Position>? _subscription;
  bool get estActif => _subscription != null;

  // Précision GPS minimale acceptée, en mètres. Au-delà, le point est
  // considéré comme un "mauvais fix" (signal faible / démarrage à froid
  // du GPS) et il est ignoré plutôt que d'être envoyé au backend.
  static const double _precisionMaxMetres = 30;

  // Vitesse maximale plausible pour un bus urbain, en m/s (≈120 km/h,
  // marge large). Un point impliquant un déplacement plus rapide que
  // ça par rapport au précédent est presque certainement une erreur
  // GPS (saut aberrant), pas un vrai mouvement du bus.
  static const double _vitesseMaxPlausibleMs = 33;

  Position? _dernierePositionAcceptee;

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

  /// Filtre les positions non fiables : précision GPS insuffisante, ou
  /// déplacement physiquement impossible par rapport au dernier point
  /// accepté (typique des faux sauts en zigzag au démarrage du GPS).
  bool _positionEstFiable(Position position) {
    if (position.accuracy > _precisionMaxMetres) {
      return false;
    }

    final derniere = _dernierePositionAcceptee;
    if (derniere == null) return true; // premier point : rien à comparer

    final distanceMetres = Geolocator.distanceBetween(
      derniere.latitude,
      derniere.longitude,
      position.latitude,
      position.longitude,
    );

    final dureeSecondes = position.timestamp.difference(derniere.timestamp).inMilliseconds / 1000;
    if (dureeSecondes <= 0) return false;

    final vitesseImpliquee = distanceMetres / dureeSecondes;
    return vitesseImpliquee <= _vitesseMaxPlausibleMs;
  }

  /// Démarre le partage : écoute le GPS et envoie chaque nouvelle position
  /// fiable au backend (qui la diffuse ensuite en temps réel aux passagers).
  Future<bool> demarrerPartage({void Function(String erreur)? onErreur}) async {
    final autorise = await _verifierPermissions();
    if (!autorise) {
      onErreur?.call("La localisation doit être activée pour partager ta position.");
      return false;
    }

    _dernierePositionAcceptee = null;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // envoie une mise à jour tous les 10 mètres minimum
    );

    Future<void> envoyerPosition(Position position) async {
      if (!_positionEstFiable(position)) return; // point GPS imprécis/aberrant : on l'ignore

      _dernierePositionAcceptee = position;

      try {
        await ApiService.post('/chauffeur/position', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'cap': position.heading,
          'vitesse': position.speed * 3.6,
        });
      } catch (e) {
        onErreur?.call(e.toString());
      }
    }

    // Position initiale : on filtre aussi le tout premier point avant
    // de démarrer le flux continu, pour ne jamais envoyer un "cold fix".
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await envoyerPosition(position);
    } catch (e) {
      onErreur?.call(e.toString());
    }

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      envoyerPosition,
      onError: (e) => onErreur?.call(e.toString()),
    );

    return true;
  }

  Future<void> arreterPartage() async {
    await _subscription?.cancel();
    _subscription = null;
    _dernierePositionAcceptee = null;
    try {
      await ApiService.post('/chauffeur/arreter-partage', {});
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
  }
}