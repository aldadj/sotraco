import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';

class RealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final Map<int, void Function(Map<String, dynamic>)> _callbacks = {};

  bool _connecte = false;
  bool _connexionEtablie = false;

  Timer? _reconnexionTimer;

  Future<void> connecter() async {
    if (_connecte && _connexionEtablie) {
      return;
    }

    _reconnexionTimer?.cancel();

    final scheme = ApiConfig.reverbUseTLS ? 'wss' : 'ws';

    final uri = Uri.parse(
      '$scheme://${ApiConfig.reverbHost}:${ApiConfig.reverbPort}/app/'
      '${ApiConfig.reverbKey}'
      '?protocol=7&client=flutter&version=8.0&flash=false',
    );

    try {
      await _subscription?.cancel();

      try {
        await _channel?.sink.close();
      } catch (_) {}

      _subscription = null;
      _channel = null;

      _connexionEtablie = false;
      _connecte = false;

      print('🔌 Connexion Reverb : $uri');

      final channel = WebSocketChannel.connect(uri);

      _channel = channel;
      _connecte = true;

      _subscription = channel.stream.listen(
        _surMessage,

        onError: (error) {
          print('❌ Reverb erreur : $error');

          _connecte = false;
          _connexionEtablie = false;

          _planifierReconnexion();
        },

        onDone: () {
          print('🔌 Reverb déconnecté');

          _connecte = false;
          _connexionEtablie = false;

          _planifierReconnexion();
        },

        cancelOnError: false,
      );

      // Attendre que Reverb envoie :
      // pusher:connection_established
      await _attendreConnexion();
    } catch (e) {
      print('❌ Impossible de connecter Reverb : $e');

      _connecte = false;
      _connexionEtablie = false;

      _planifierReconnexion();

      rethrow;
    }
  }

  Future<void> _attendreConnexion() async {
    const timeout = Duration(seconds: 10);

    final debut = DateTime.now();

    while (!_connexionEtablie) {
      if (DateTime.now().difference(debut) > timeout) {
        throw TimeoutException(
          'Reverb n’a pas établi la connexion dans les délais.',
        );
      }

      await Future.delayed(
        const Duration(milliseconds: 100),
      );
    }
  }

  void _surMessage(dynamic message) {
    try {
      print('📡 Reverb ← $message');

      final decodedPayload = jsonDecode(message);

      if (decodedPayload is! Map) {
        return;
      }

      final Map<String, dynamic> payload =
          Map<String, dynamic>.from(decodedPayload);

      final event = payload['event']?.toString();

      // ==========================================================
      // CONNEXION ÉTABLIE
      // ==========================================================

      if (event == 'pusher:connection_established') {
        _connexionEtablie = true;

        print('✅ Connexion Reverb établie');

        // Réabonner tous les bus après une reconnexion.
        for (final busId in _callbacks.keys.toList()) {
          _envoyerAbonnement(busId);
        }

        return;
      }

      // ==========================================================
      // PING
      // ==========================================================

      if (event == 'pusher:ping') {
        _channel?.sink.add(
          jsonEncode({
            'event': 'pusher:pong',
            'data': {},
          }),
        );

        return;
      }

      // ==========================================================
      // PONG
      // ==========================================================

      if (event == 'pusher:pong') {
        return;
      }

      // ==========================================================
      // ERREUR REVERB
      // ==========================================================

      if (event == 'pusher:error') {
        print(
          '❌ Erreur Reverb : ${payload['data']}',
        );

        return;
      }

      // ==========================================================
      // CANAL
      // ==========================================================

      final channel = payload['channel']?.toString();

      if (channel == null) {
        return;
      }

      // ==========================================================
      // POSITION BUS
      // ==========================================================

      if (event == 'position.maj' &&
          channel.startsWith('bus.')) {
        final busId = int.tryParse(
          channel.replaceFirst('bus.', ''),
        );

        if (busId == null) {
          return;
        }

        // --------------------------------------------------------
        // Récupération sécurisée de data
        // --------------------------------------------------------

        final rawData = payload['data'];

        Map<String, dynamic>? data;

        if (rawData is String) {
          final decodedData = jsonDecode(rawData);

          if (decodedData is Map) {
            data = Map<String, dynamic>.from(
              decodedData,
            );
          }
        } else if (rawData is Map) {
          data = Map<String, dynamic>.from(
            rawData,
          );
        }

        if (data == null) {
          return;
        }

        print(
          '🚌 Position bus $busId : '
          '${data['latitude']}, '
          '${data['longitude']}',
        );

        // --------------------------------------------------------
        // Envoyer la nouvelle position au callback
        // --------------------------------------------------------

        _callbacks[busId]?.call(data);

        return;
      }
    } catch (e) {
      print(
        '⚠️ Message Reverb ignoré : $e',
      );
    }
  }

  // ============================================================
  // ABONNEMENT
  // ============================================================

  void _envoyerAbonnement(int busId) {
    if (!_connecte || !_connexionEtablie) {
      return;
    }

    final message = {
      'event': 'pusher:subscribe',
      'data': {
        'channel': 'bus.$busId',
      },
    };

    print(
      '📡 Abonnement au canal bus.$busId',
    );

    _channel?.sink.add(
      jsonEncode(message),
    );
  }

  // ============================================================
  // SUIVRE UN BUS
  // ============================================================

  Future<void> suivreBus(
    int busId,
    void Function(Map<String, dynamic>) onPosition,
  ) async {
    _callbacks[busId] = onPosition;

    if (!_connecte || !_connexionEtablie) {
      await connecter();
    }

    _envoyerAbonnement(busId);
  }

  // ============================================================
  // ARRÊTER LE SUIVI
  // ============================================================

  Future<void> arreterSuivi(int busId) async {
    _callbacks.remove(busId);

    if (!_connecte || !_connexionEtablie) {
      return;
    }

    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': 'bus.$busId',
        },
      }),
    );

    print(
      '📡 Désabonnement bus.$busId',
    );
  }

  // ============================================================
  // RECONNEXION
  // ============================================================

  void _planifierReconnexion() {
    if (_callbacks.isEmpty) {
      return;
    }

    _reconnexionTimer?.cancel();

    _reconnexionTimer = Timer(
      const Duration(seconds: 3),
      () async {
        try {
          print(
            '🔄 Tentative de reconnexion Reverb...',
          );

          await connecter();
        } catch (e) {
          print(
            '❌ Reconnexion échouée : $e',
          );
        }
      },
    );
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  Future<void> deconnecter() async {
    _reconnexionTimer?.cancel();
    _reconnexionTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;

    _connecte = false;
    _connexionEtablie = false;

    _callbacks.clear();
  }
}