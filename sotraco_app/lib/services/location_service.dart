import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

/// Service responsable du GPS du chauffeur.
///
/// Fonctionnement :
/// 1. Vérifie que le GPS du téléphone est activé.
/// 2. Demande les permissions nécessaires.
/// 3. Récupère immédiatement une première position fiable.
/// 4. Écoute ensuite les changements de position.
/// 5. Envoie les positions au backend Laravel.
/// 6. Peut arrêter temporairement le partage sans terminer le trajet.
class LocationService {
  StreamSubscription<Position>? _subscription;

  Position? _dernierePositionAcceptee;

  bool get estActif => _subscription != null;

  /// Précision GPS maximale acceptée.
  ///
  /// Une précision de 30 mètres signifie que les positions dont
  /// l'incertitude est supérieure à 30 m sont ignorées.
  static const double _precisionMaxMetres = 30;

  /// Vitesse maximale plausible pour un bus urbain.
  ///
  /// 33 m/s ≈ 119 km/h.
  /// Cela permet d'éviter les gros sauts GPS.
  static const double _vitesseMaxPlausibleMs = 33;

  // ==========================================================================
  // PERMISSIONS GPS
  // ==========================================================================

  Future<bool> _verifierPermissions({
    void Function(String erreur)? onErreur,
  }) async {
    try {
      // Vérifier si le service de localisation du téléphone est actif.
      final serviceActif = await Geolocator.isLocationServiceEnabled();

      if (!serviceActif) {
        onErreur?.call(
          'La localisation du téléphone est désactivée. '
          'Activez le GPS puis réessayez.',
        );
        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      // Permission refusée : demander à nouveau.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          onErreur?.call(
            'La permission de localisation a été refusée.',
          );
          return false;
        }
      }

      // Permission refusée définitivement.
      if (permission == LocationPermission.deniedForever) {
        onErreur?.call(
          'La permission de localisation est définitivement refusée. '
          'Autorisez la localisation dans les paramètres du téléphone.',
        );
        return false;
      }

      return true;
    } catch (e) {
      onErreur?.call(
        'Impossible de vérifier la localisation : $e',
      );
      return false;
    }
  }

  // ==========================================================================
  // VALIDATION DES POSITIONS
  // ==========================================================================

  bool _positionEstFiable(Position position) {
    // Position trop imprécise.
    if (position.accuracy > _precisionMaxMetres) {
      return false;
    }

    final derniere = _dernierePositionAcceptee;

    // Première position : aucune comparaison possible.
    if (derniere == null) {
      return true;
    }

    final distanceMetres = Geolocator.distanceBetween(
      derniere.latitude,
      derniere.longitude,
      position.latitude,
      position.longitude,
    );

    final differenceTemps =
        position.timestamp.difference(derniere.timestamp);

    final dureeSecondes =
        differenceTemps.inMilliseconds / 1000;

    // Éviter une division par zéro ou une position dont
    // l'heure est antérieure à la précédente.
    if (dureeSecondes <= 0) {
      return false;
    }

    final vitesseImpliquee =
        distanceMetres / dureeSecondes;

    // Si le déplacement implique une vitesse impossible,
    // on considère le point comme un saut GPS.
    if (vitesseImpliquee > _vitesseMaxPlausibleMs) {
      return false;
    }

    return true;
  }

  // ==========================================================================
  // DÉMARRER LE PARTAGE
  // ==========================================================================

 Future<bool> demarrerPartage({
  void Function(String erreur)? onErreur,
}) async {
  if (_subscription != null) {
    return true;
  }

  final autorise = await _verifierPermissions(
    onErreur: onErreur,
  );

  if (!autorise) {
    return false;
  }

  _dernierePositionAcceptee = null;

  bool positionEnvoyeeAvecSucces = false;

  Future<bool> envoyerPosition(Position position) async {
    if (!_positionEstFiable(position)) {
      return false;
    }

    try {
      final response = await ApiService.post(
        '/chauffeur/position',
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'cap': position.heading >= 0
              ? position.heading
              : null,
          'vitesse': position.speed >= 0
              ? position.speed * 3.6
              : null,
        },
      );

      _dernierePositionAcceptee = position;
      positionEnvoyeeAvecSucces = true;

      return true;
    } catch (e) {
      onErreur?.call(e.toString());
      return false;
    }
  }

  // ============================================================
  // PREMIÈRE POSITION
  // ============================================================

  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final succes = await envoyerPosition(position);

    if (!succes) {
      return false;
    }
  } catch (e) {
    onErreur?.call(
      'Impossible de récupérer la position GPS : $e',
    );

    return false;
  }

  // ============================================================
  // FLUX GPS
  // ============================================================

  const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  _subscription = Geolocator.getPositionStream(
    locationSettings: settings,
  ).listen(
    (position) async {
      await envoyerPosition(position);
    },
    onError: (error) {
      onErreur?.call(
        'Erreur du GPS : $error',
      );
    },
  );

  return positionEnvoyeeAvecSucces;
}
  // ==========================================================================
  // ARRÊTER LE PARTAGE GPS
  // ==========================================================================

  Future<void> arreterPartage() async {
    // Arrêter l'écoute GPS sur le téléphone.
    await _subscription?.cancel();

    _subscription = null;

    _dernierePositionAcceptee = null;

    // Informer Laravel que le chauffeur ne partage plus
    // temporairement sa position.
    try {
      await ApiService.post(
        '/chauffeur/arreter-partage',
        {},
      );
    } catch (_) {
      // On ne bloque pas l'application si le serveur
      // ne répond pas lors de l'arrêt.
    }
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _dernierePositionAcceptee = null;
  }
}