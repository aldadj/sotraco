class Bus {
  int id;
  String numero;

  String? immatriculation;
  String? statut;

  int? ligneId;
  String? ligneNom;
  String? chauffeurNom;
  String? sens;

  double? latitude;
  double? longitude;

  double? cap;
  double? vitesse;

  bool enMarche;
  bool enDirect;

  DateTime? dernierePosition;

  Bus({
    required this.id,
    required this.numero,
    this.immatriculation,
    this.statut,
    this.ligneId,
    this.ligneNom,
    this.chauffeurNom,
    this.sens,
    this.latitude,
    this.longitude,
    this.cap,
    this.vitesse,
    this.enMarche = false,
    this.enDirect = false,
    this.dernierePosition,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    final ligne = json['ligne'] is Map
        ? Map<String, dynamic>.from(json['ligne'])
        : null;

    final trajet = json['trajet_actif'] is Map
        ? Map<String, dynamic>.from(json['trajet_actif'])
        : null;

    final chauffeur = trajet?['chauffeur'] is Map
        ? Map<String, dynamic>.from(trajet!['chauffeur'])
        : null;

    return Bus(
      id: (json['id'] as num).toInt(),

      numero: json['numero']?.toString() ?? '',

      immatriculation: json['immatriculation']?.toString(),

      statut: json['statut']?.toString(),

      ligneId: json['ligne_id'] != null
          ? (json['ligne_id'] as num).toInt()
          : ligne?['id'] != null
              ? (ligne!['id'] as num).toInt()
              : null,

      ligneNom: ligne?['nom']?.toString(),

      chauffeurNom: chauffeur?['name']?.toString(),

      sens: trajet?['sens']?.toString() ?? json['sens']?.toString(),

      latitude: _toDouble(
        json['derniere_latitude'] ?? json['latitude'],
      ),

      longitude: _toDouble(
        json['derniere_longitude'] ?? json['longitude'],
      ),

      cap: _toDouble(
        json['dernier_cap'] ?? json['cap'],
      ),

      vitesse: _toDouble(
        json['derniere_vitesse'] ?? json['vitesse'],
      ),

      enMarche: json['en_marche'] == true,

      enDirect: json['en_direct'] == true,

      dernierePosition: _toDateTime(
        json['derniere_position_a'] ?? json['capture_a'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  /// Applique une nouvelle position reçue depuis Reverb.
  void appliquerPosition(Map<String, dynamic> data) {
    final lat = _toDouble(data['latitude']);
    final lng = _toDouble(data['longitude']);

    if (lat != null) {
      latitude = lat;
    }

    if (lng != null) {
      longitude = lng;
    }

    final nouveauCap = _toDouble(data['cap']);
    if (nouveauCap != null) {
      cap = nouveauCap;
    }

    final nouvelleVitesse = _toDouble(data['vitesse']);
    if (nouvelleVitesse != null) {
      vitesse = nouvelleVitesse;
    }

    if (data['en_marche'] != null) {
      enMarche = data['en_marche'] == true;
    }

    if (data['en_direct'] != null) {
      enDirect = data['en_direct'] == true;
    } else {
      // Une position reçue par Reverb signifie que le bus vient
      // de communiquer sa position.
      enDirect = true;
    }

    if (data['sens'] != null) {
      sens = data['sens']?.toString();
    }

    if (data['ligne_id'] != null) {
      ligneId = (data['ligne_id'] as num).toInt();
    }

    if (data['capture_a'] != null) {
      dernierePosition = DateTime.tryParse(
        data['capture_a'].toString(),
      );
    }
  }
}