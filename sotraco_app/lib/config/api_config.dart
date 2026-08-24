class ApiConfig {
  // L'URL peut être remplacée au build avec --dart-define=API_BASE_URL=...
  // - Émulateur Android : 10.0.2.2 pointe vers le "localhost" de ta machine
  // - Appareil réel / production : URL publique (ex: https://api.sotraco.bf)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.68:8000/api',
  );

  // Config Reverb (serveur websocket, protocole compatible Pusher)
  static const String reverbKey = '6qxm3fstftponph5twwl'; // valeur générée par `php artisan reverb:install`
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '192.168.1.68',
  );
  static const int reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const bool reverbUseTLS = bool.fromEnvironment('REVERB_TLS', defaultValue: false);
}
