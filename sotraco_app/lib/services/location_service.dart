import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

/// Service GPS du chauffeur.
///
/// Compatible :
/// - Android
/// - iOS
/// - Web / Edge / Chrome
///
/// Fonctionnement :
/// 1. Vérifie les permissions.
/// 2. Demande une première position GPS.
/// 3. Envoie cette position à Laravel.
/// 4. Démarre le suivi continu.
/// 5. Envoie les nouvelles positions.
/// 6. Peut arrêter le partage.
class LocationService {
  StreamSubscription<Position>? _subscription;

  Position? _dernierePositionAcceptee;

  bool get estActif => _subscription != null;

  /// Précision maximale acceptée.
  static const double _precisionMaxMetres = 300;

  /// Vitesse maximale plausible.
  ///
  /// 50 m/s = 180 km/h.
  ///
  /// On laisse une marge importante pour éviter de bloquer
  /// inutilement les GPS des téléphones.
  static const double _vitesseMaxPlausibleMs = 40;

  // ==========================================================================
  // VÉRIFICATION GPS / PERMISSIONS
  // ==========================================================================

  Future<bool> verifierGPS({
    void Function(String erreur)? onErreur,
  }) async {
    try {
      // ======================================================================
      // WEB
      // ======================================================================

      if (kIsWeb) {
        LocationPermission permission =
            await Geolocator.checkPermission();

        debugPrint(
          '🌐 Permission localisation Web : $permission',
        );

        if (permission == LocationPermission.denied) {
          permission =
              await Geolocator.requestPermission();

          debugPrint(
            '🌐 Permission après demande : $permission',
          );
        }

        if (permission == LocationPermission.denied) {
          onErreur?.call(
            'La permission de localisation a été refusée. '
            'Cliquez sur "Autoriser" dans Edge puis réessayez.',
          );

          return false;
        }

        if (permission == LocationPermission.deniedForever) {
          onErreur?.call(
            'La localisation est bloquée pour ce site. '
            'Cliquez sur le cadenas à gauche de l’adresse du site '
            'dans Edge, puis autorisez la localisation.',
          );

          return false;
        }

        // Sur Web, on ne bloque PAS sur
        // isLocationServiceEnabled().
        //
        // Le meilleur test consiste à demander réellement
        // une position au navigateur.
        return true;
      }

      // ======================================================================
      // ANDROID / IOS
      // ======================================================================

      final serviceActif =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceActif) {
        onErreur?.call(
          'La localisation du téléphone est désactivée. '
          'Activez le GPS puis réessayez.',
        );

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          onErreur?.call(
            'La permission de localisation a été refusée.',
          );

          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onErreur?.call(
          'La permission de localisation est définitivement refusée. '
          'Autorisez-la dans les paramètres du téléphone.',
        );

        return false;
      }

      return true;
    } catch (e) {
      debugPrint(
        '❌ Erreur vérification GPS : $e',
      );

      onErreur?.call(
        'Impossible de vérifier la localisation : $e',
      );

      return false;
    }
  }

  // ==========================================================================
  // VALIDATION POSITION
  // ==========================================================================

bool _positionEstFiable(Position position) {
  // Première position :
  // on accepte une précision allant jusqu'à 500 mètres.
  if (_dernierePositionAcceptee == null) {
    if (position.accuracy > 500) {
      debugPrint(
        '⚠️ Première position trop imprécise : '
        '${position.accuracy.toStringAsFixed(1)} m',
      );
      return false;
    }

    debugPrint(
      '✅ Première position acceptée : '
      '${position.accuracy.toStringAsFixed(1)} m',
    );

    return true;
  }

  // Positions suivantes :
  // on exige une précision maximale de 50 mètres.
  if (position.accuracy > _precisionMaxMetres) {
    debugPrint(
      '⚠️ Position ignorée : précision '
      '${position.accuracy.toStringAsFixed(1)} m',
    );
    return false;
  }

  final derniere = _dernierePositionAcceptee!;

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

  if (dureeSecondes <= 0) {
    debugPrint(
      '⚠️ Position ignorée : temps invalide.',
    );
    return false;
  }

  final vitesseImpliquee =
      distanceMetres / dureeSecondes;

  if (vitesseImpliquee > _vitesseMaxPlausibleMs) {
    debugPrint(
      '⚠️ Position ignorée : déplacement impossible '
      '(${vitesseImpliquee.toStringAsFixed(1)} m/s)',
    );
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
    // ------------------------------------------------------------------------
    // Déjà actif
    // ------------------------------------------------------------------------

    if (_subscription != null) {
      debugPrint(
        'ℹ️ Le partage GPS est déjà actif.',
      );

      return true;
    }

    // ------------------------------------------------------------------------
    // Vérifier les permissions
    // ------------------------------------------------------------------------

    final gpsDisponible =
        await verifierGPS(
      onErreur: onErreur,
    );

    if (!gpsDisponible) {
      return false;
    }

    _dernierePositionAcceptee = null;

    bool positionEnvoyee = false;

    // =========================================================================
    // ENVOYER POSITION
    // =========================================================================

    Future<bool> envoyerPosition(
      Position position,
    ) async {
      debugPrint(
        '📍 GPS reçu : '
        '${position.latitude}, '
        '${position.longitude} '
        '| précision=${position.accuracy}m',
      );

      if (!_positionEstFiable(position)) {
        return false;
      }

      try {
        final Map<String, dynamic> donnees = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };

        // Cap
        if (position.heading >= 0) {
          donnees['cap'] =
              position.heading;
        }

        // Vitesse en km/h
        if (position.speed >= 0) {
          donnees['vitesse'] =
              position.speed * 3.6;
        }

        debugPrint(
          '📤 Envoi position Laravel : $donnees',
        );

        await ApiService.post(
          '/chauffeur/position',
          donnees,
        );

        _dernierePositionAcceptee =
            position;

        positionEnvoyee = true;

        debugPrint(
          '✅ Position envoyée avec succès.',
        );

        return true;
      } on ApiException catch (e) {
        debugPrint(
          '❌ Erreur API GPS : ${e.message}',
        );

        onErreur?.call(
          'Erreur serveur GPS : ${e.message}',
        );

        return false;
      } catch (e) {
        debugPrint(
          '❌ Erreur envoi GPS : $e',
        );

        onErreur?.call(
          'Erreur lors de l’envoi de la position : $e',
        );

        return false;
      }
    }

    // =========================================================================
    // PREMIÈRE POSITION
    // =========================================================================

    try {
      debugPrint(
        '📡 Recherche de la première position GPS...',
      );

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
        timeLimit:
            const Duration(seconds: 20),
      );

      debugPrint(
        '📍 Première position obtenue : '
        '${position.latitude}, '
        '${position.longitude}',
      );

      final succes =
          await envoyerPosition(position);

      if (!succes) {
        debugPrint(
          '❌ Première position non envoyée.',
        );

        return false;
      }
    } on TimeoutException {
      debugPrint(
        '❌ Timeout GPS.',
      );

      onErreur?.call(
        kIsWeb
            ? 'Edge met trop de temps à fournir votre position. '
              'Vérifiez que la localisation est autorisée pour ce site.'
            : 'Le GPS met trop de temps à fournir une position. '
              'Vérifiez que la localisation est activée.',
      );

      return false;
    } catch (e) {
      debugPrint(
        '❌ Erreur récupération GPS : $e',
      );

      onErreur?.call(
        kIsWeb
            ? 'Impossible de récupérer votre position dans Edge. '
              'Vérifiez que la localisation est autorisée pour ce site '
              'et que vous utilisez HTTPS ou localhost.'
            : 'Impossible de récupérer la position GPS : $e',
      );

      return false;
    }

    // =========================================================================
    // FLUX GPS
    // =========================================================================

    try {
      const LocationSettings settings =
          LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      debugPrint(
        '📡 Démarrage du flux GPS...',
      );

      _subscription =
          Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (Position position) async {
          await envoyerPosition(position);
        },
        onError: (error) {
          debugPrint(
            '❌ Erreur flux GPS : $error',
          );

          onErreur?.call(
            'Erreur du GPS : $error',
          );
        },
        cancelOnError: false,
      );

      debugPrint(
        '✅ Flux GPS démarré.',
      );

      return positionEnvoyee;
    } catch (e) {
      debugPrint(
        '❌ Impossible de démarrer le flux GPS : $e',
      );

      onErreur?.call(
        'Impossible de démarrer le suivi GPS : $e',
      );

      return false;
    }
  }

  // ==========================================================================
  // ARRÊTER LE PARTAGE
  // ==========================================================================

  Future<void> arreterPartage() async {
    debugPrint(
      '🛑 Arrêt du partage GPS...',
    );

    await _subscription?.cancel();

    _subscription = null;

    _dernierePositionAcceptee = null;

    try {
      await ApiService.post(
        '/chauffeur/arreter-partage',
        {},
      );

      debugPrint(
        '✅ Laravel informé de l’arrêt du GPS.',
      );
    } catch (e) {
      debugPrint(
        '⚠️ Impossible d’informer Laravel : $e',
      );
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