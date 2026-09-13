class ApiConfig {
  /// API Laravel
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.11.124:8000/api',
  );

  /// Clé publique Reverb
  static const String reverbKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '6qxm3fstftponph5twwl',
  );

  /// Adresse du serveur Reverb
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '192.168.11.124',
  );

  /// Port Reverb
  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 8080,
  );

  /// false en développement local
  static const bool reverbUseTLS = bool.fromEnvironment(
    'REVERB_TLS',
    defaultValue: false,
  );
}