class AppUser {
  final int id;
  final String name;
  final String email;
  final String? telephone;
  final String role;

  /// Trajet actuellement actif du chauffeur.
  ///
  /// Exemple :
  /// {
  ///   "id": 1,
  ///   "chauffeur_id": 2,
  ///   "bus_id": 4,
  ///   "ligne_id": 1,
  ///   "statut": "en_cours",
  ///   "bus": {...},
  ///   "ligne": {...}
  /// }
  final Map<String, dynamic>? trajetActif;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.telephone,
    required this.role,
    this.trajetActif,
  });

  // ---------------------------------------------------------------------------
  // RÔLES
  // ---------------------------------------------------------------------------

  bool get isChauffeur => role == 'chauffeur';

  bool get isAdmin => role == 'admin';

  bool get isPassager => role == 'passager';

  // ---------------------------------------------------------------------------
  // BUS ASSIGNÉ
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? get busAssigne {
    final trajet = trajetActif;

    if (trajet == null) {
      return null;
    }

    final bus = trajet['bus'];

    if (bus is Map) {
      return Map<String, dynamic>.from(bus);
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // LIGNE ASSIGNÉE
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? get ligneAssignee {
    final trajet = trajetActif;

    if (trajet == null) {
      return null;
    }

    final ligne = trajet['ligne'];

    if (ligne is Map) {
      return Map<String, dynamic>.from(ligne);
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // INFORMATIONS PRATIQUES
  // ---------------------------------------------------------------------------

  bool get aUnTrajetActif => trajetActif != null;

  bool get aUnBusAssigne => busAssigne != null;

  bool get aUneLigneAssignee => ligneAssignee != null;

  String? get numeroBus {
    final bus = busAssigne;

    if (bus == null) {
      return null;
    }

    return bus['numero']?.toString();
  }

  String? get immatriculationBus {
    final bus = busAssigne;

    if (bus == null) {
      return null;
    }

    return bus['immatriculation']?.toString();
  }

  String? get nomLigne {
    final ligne = ligneAssignee;

    if (ligne == null) {
      return null;
    }

    return ligne['nom']?.toString();
  }

  String? get codeLigne {
    final ligne = ligneAssignee;

    if (ligne == null) {
      return null;
    }

    return ligne['code']?.toString();
  }

  String? get departLigne {
    final ligne = ligneAssignee;

    if (ligne == null) {
      return null;
    }

    return ligne['depart']?.toString();
  }

  String? get destinationLigne {
    final ligne = ligneAssignee;

    if (ligne == null) {
      return null;
    }

    return ligne['destination']?.toString();
  }

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  factory AppUser.fromJson(Map<String, dynamic> json) {
    /*
     * Laravel peut retourner la relation sous forme :
     *
     * "trajet_actif"
     *
     * selon la sérialisation.
     *
     * On accepte également :
     *
     * "trajetActif"
     *
     * pour être plus robuste côté Flutter.
     */
    final trajet = json['trajetActif'] ?? json['trajet_actif'];

    return AppUser(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      role: json['role'] ?? 'passager',
      trajetActif: trajet is Map
          ? Map<String, dynamic>.from(trajet)
          : null,
    );
  }
}