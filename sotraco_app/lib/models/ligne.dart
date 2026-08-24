class Ligne {
  final int id;
  final String code;
  final String nom;
  final String? depart;
  final String? destination;
  final String couleur;
  final String? description;
  final int? busesCount;

  Ligne({
    required this.id,
    required this.code,
    required this.nom,
    this.depart,
    this.destination,
    required this.couleur,
    this.description,
    this.busesCount,
  });

  factory Ligne.fromJson(Map<String, dynamic> json) => Ligne(
        id: json['id'],
        code: json['code'],
        nom: json['nom'],
        depart: json['depart'],
        destination: json['destination'],
        couleur: json['couleur'] ?? '#1E824C',
        description: json['description'],
        busesCount: json['buses_count'],
      );
}
