class Bus {
  final int id;
  final String numero;
  final String immatriculation;
  final int? ligneId;
  final String? ligneNom;
  final String? chauffeurNom;
  String? sens;
  final String statut;
  bool enMarche;
  bool enDirect;
  double? latitude;
  double? longitude;
  double? cap;
  double? vitesse;

  Bus({
    required this.id,
    required this.numero,
    required this.immatriculation,
    this.ligneId,
    this.ligneNom,
    this.chauffeurNom,
    this.sens,
    required this.statut,
    this.enMarche = false,
    this.enDirect = false,
    this.latitude,
    this.longitude,
    this.cap,
    this.vitesse,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        id: json['id'],
        numero: json['numero'],
        immatriculation: json['immatriculation'],
        ligneId: json['ligne_id'],
        ligneNom: json['ligne']?['nom'],
        chauffeurNom: json['chauffeur']?['name'] ?? json['trajet_actif']?['chauffeur']?['name'],
        sens: json['sens'] ?? json['trajet_actif']?['sens'],
        statut: json['statut'] ?? 'inactif',
        enMarche: json['en_marche'] ?? false,
        enDirect: json['en_direct'] ?? false,
        latitude: (json['derniere_latitude'] as num?)?.toDouble(),
        longitude: (json['derniere_longitude'] as num?)?.toDouble(),
        cap: (json['dernier_cap'] as num?)?.toDouble(),
        vitesse: (json['derniere_vitesse'] as num?)?.toDouble(),
      );

  /// Met à jour la position depuis un évènement websocket "position.maj"
  void appliquerPosition(Map<String, dynamic> data) {
    latitude = (data['latitude'] as num?)?.toDouble();
    longitude = (data['longitude'] as num?)?.toDouble();
    cap = (data['cap'] as num?)?.toDouble();
    vitesse = (data['vitesse'] as num?)?.toDouble();
    sens = data['sens'] ?? sens;
    enMarche = data['en_marche'] ?? enMarche;
    enDirect = enMarche;
  }
}
