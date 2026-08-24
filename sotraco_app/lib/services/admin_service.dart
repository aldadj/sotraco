import 'api_service.dart';

/// Regroupe tous les appels réservés à l'admin : CRUD bus, lignes, et
/// liste des chauffeurs disponibles (pour les assigner à un bus).
class AdminService {
  // --- Chauffeurs ---
  static Future<Map<String, dynamic>> creerChauffeur({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? telephone,
  }) async {
    final data = await ApiService.post('/chauffeurs', {
      'name': name,
      'email': email,
      'telephone': telephone,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> listerChauffeurs() async {
    final data = await ApiService.get('/chauffeurs');
    return List<Map<String, dynamic>>.from(data);
  }

  // --- Lignes ---
  static Future<Map<String, dynamic>> creerLigne({
    required String code,
    required String nom,
    required String depart,
    required String destination,
    String? couleur,
    String? description,
  }) async {
    final data = await ApiService.post('/lignes', {
      'code': code,
      'nom': nom,
      'depart': depart,
      'destination': destination,
      'couleur': couleur,
      'description': description,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> modifierLigne(
    int id, {
    String? code,
    String? nom,
    String? depart,
    String? destination,
    String? couleur,
    String? description,
    bool? actif,
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (nom != null) body['nom'] = nom;
    if (depart != null) body['depart'] = depart;
    if (destination != null) body['destination'] = destination;
    if (couleur != null) body['couleur'] = couleur;
    if (description != null) body['description'] = description;
    if (actif != null) body['actif'] = actif;
    final data = await ApiService.put('/lignes/$id', body);
    return Map<String, dynamic>.from(data);
  }

  static Future<void> supprimerLigne(int id) => ApiService.delete('/lignes/$id');

  // --- Bus ---
  static Future<Map<String, dynamic>> creerBus({
    required String numero,
    required String immatriculation,
    int? capacite,
    int? ligneId,
    String statut = 'actif',
  }) async {
    final data = await ApiService.post('/buses', {
      'numero': numero,
      'immatriculation': immatriculation,
      'capacite': capacite,
      'ligne_id': ligneId,
      'statut': statut,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> modifierBus(
    int id, {
    String? numero,
    String? immatriculation,
    int? capacite,
    int? ligneId,
    String? statut,
  }) async {
    final body = <String, dynamic>{};
    if (numero != null) body['numero'] = numero;
    if (immatriculation != null) body['immatriculation'] = immatriculation;
    if (capacite != null) body['capacite'] = capacite;
    body['ligne_id'] = ligneId; // peut être null volontairement (désassigner)
    if (statut != null) body['statut'] = statut;
    final data = await ApiService.put('/buses/$id', body);
    return Map<String, dynamic>.from(data);
  }

  static Future<void> supprimerBus(int id) => ApiService.delete('/buses/$id');
}
