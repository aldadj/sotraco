import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // ---------------------------------------------------------------------------
  // CONNEXION
  // ---------------------------------------------------------------------------

  static Future<AppUser> login(
    String email,
    String password,
  ) async {
    final data = await ApiService.post(
      '/login',
      {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    await ApiService.saveToken(data['token']);

    return AppUser.fromJson(
      Map<String, dynamic>.from(data['user']),
    );
  }

  // ---------------------------------------------------------------------------
  // INSCRIPTION
  // ---------------------------------------------------------------------------

  static Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? telephone,
    String role = 'passager',
  }) async {
    final data = await ApiService.post(
      '/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'telephone': telephone,
        'role': role,
      },
      auth: false,
    );

    await ApiService.saveToken(data['token']);

    return AppUser.fromJson(
      Map<String, dynamic>.from(data['user']),
    );
  }

  // ---------------------------------------------------------------------------
  // UTILISATEUR CONNECTÉ
  // ---------------------------------------------------------------------------

  static Future<AppUser?> currentUser() async {
    final token = await ApiService.getToken();

    if (token == null) {
      return null;
    }

    try {
      final data = await ApiService.get('/me');

      return AppUser.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      await ApiService.clearToken();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // DÉCONNEXION
  // ---------------------------------------------------------------------------

  static Future<void> logout() async {
    try {
      await ApiService.post(
        '/logout',
        {},
      );
    } catch (_) {
      // Même si le token est déjà expiré,
      // on nettoie le token localement.
    }

    await ApiService.clearToken();
  }
}