import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

/// Client websocket léger parlant le "protocole Pusher" utilisé par
/// Laravel Reverb. On évite le package pusher_channels_flutter car il ne
/// permet pas de configurer un hôte personnalisé (il cible uniquement
/// les serveurs pusher.com officiels) — ici on implémente directement
/// les quelques messages nécessaires : connexion, abonnement à un canal,
/// réception d'évènements.
class RealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final Map<int, void Function(Map<String, dynamic> data)> _callbacks = {};
  bool _connecte = false;
  Timer? _reconnexionTimer;

  Future<void> connecter() async {
    if (_connecte) return;

    final scheme = ApiConfig.reverbUseTLS ? 'wss' : 'ws';
    final uri = Uri.parse(
      '$scheme://${ApiConfig.reverbHost}:${ApiConfig.reverbPort}/app/${ApiConfig.reverbKey}'
      '?protocol=7&client=flutter&version=8.0&flash=false',
    );

    _channel = WebSocketChannel.connect(uri);
    _connecte = true;

    _subscription = _channel!.stream.listen(
      _surMessage,
      onError: (e) {
        _connecte = false;
        _planifierReconnexion();
      },
      onDone: () {
        _connecte = false;
        _planifierReconnexion();
      },
    );
  }

  void _planifierReconnexion() {
    _reconnexionTimer?.cancel();
    _reconnexionTimer = Timer(const Duration(seconds: 3), () async {
      await connecter();
      // Réabonne tous les canaux suivis avant la coupure
      for (final busId in _callbacks.keys) {
        _envoyerAbonnement(busId);
      }
    });
  }

  void _surMessage(dynamic message) {
    try {
      final Map<String, dynamic> payload = jsonDecode(message);
      final String? event = payload['event'];
      final String? channel = payload['channel'];

      if (event == 'pusher:connection_established') {
        return; // rien à faire, la connexion est prête
      }

      // On écoute l'évènement "position.maj" tel que défini par
      // broadcastAs() dans BusPositionUpdated côté Laravel.
      if (event == 'position.maj' && channel != null && channel.startsWith('bus.')) {
        final busId = int.tryParse(channel.replaceFirst('bus.', ''));
        if (busId == null) return;

        final rawData = payload['data'];
        final Map<String, dynamic> data = rawData is String ? jsonDecode(rawData) : rawData;

        _callbacks[busId]?.call(data);
      }
    } catch (_) {
      // message non pertinent (ping interne, etc.) — on ignore
    }
  }

  void _envoyerAbonnement(int busId) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': 'bus.$busId'},
    }));
  }

  /// S'abonne à la position en direct d'un bus précis.
  Future<void> suivreBus(int busId, void Function(Map<String, dynamic> data) onPosition) async {
    await connecter();
    _callbacks[busId] = onPosition;
    _envoyerAbonnement(busId);
  }

  Future<void> arreterSuivi(int busId) async {
    _callbacks.remove(busId);
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:unsubscribe',
      'data': {'channel': 'bus.$busId'},
    }));
  }

  Future<void> deconnecter() async {
    _reconnexionTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connecte = false;
    _callbacks.clear();
  }
}
