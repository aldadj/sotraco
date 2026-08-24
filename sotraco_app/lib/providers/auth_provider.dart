import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _chargement = true;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  AppUser? get user => _user;

  bool get estConnecte => _user != null;

  bool get chargement => _chargement;

  // ---------------------------------------------------------------------------
  // INITIALISATION
  // ---------------------------------------------------------------------------

  Future<void> initialiser() async {
    try {
      _user = await AuthService.currentUser();
    } catch (_) {
      _user = null;
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // CONNEXION
  // ---------------------------------------------------------------------------

  Future<void> connecter(
    String email,
    String password,
  ) async {
    _user = await AuthService.login(
      email,
      password,
    );

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INSCRIPTION
  // ---------------------------------------------------------------------------

  Future<void> inscrire({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? telephone,
    String role = 'passager',
  }) async {
    _user = await AuthService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      telephone: telephone,
      role: role,
    );

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DÉCONNEXION
  // ---------------------------------------------------------------------------

  Future<void> deconnecter() async {
    await AuthService.logout();

    _user = null;

    notifyListeners();
  }
}