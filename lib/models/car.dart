class Car {
  const Car({
    required this.id,
    required this.nom,
    required this.marque,
    required this.possedee,
    this.classementRoute,
    this.classementTerre,
    this.categorie,
    this.securite,
    this.style,
    this.nombrePlaces,
    this.modeleBase,
    this.stats,
    this.image,
    this.petiteImage,
    this.logoMarque,
    this.unique = false,
  }) : assert(classementRoute == null || (classementRoute >= 1 && classementRoute <= 999)),
       assert(classementTerre == null || (classementTerre >= 1 && classementTerre <= 999));

  final String id;
  final String nom;
  final String marque;
  final bool possedee;
  final String? categorie;
  final String? securite;
  final String? style;
  final int? nombrePlaces;
  final int? classementRoute;
  final int? classementTerre;
  final String? modeleBase;
  final CarStats? stats;
  final String? image;
  final String? petiteImage;
  final String? logoMarque;
  final bool unique;

  Car copyWith({bool? possedee}) {
    return Car(
      id: id,
      nom: nom,
      marque: marque,
      possedee: possedee ?? this.possedee,
      categorie: categorie,
      securite: securite,
      style: style,
      nombrePlaces: nombrePlaces,
      classementRoute: classementRoute,
      classementTerre: classementTerre,
      modeleBase: modeleBase,
      stats: stats,
      image: image,
      petiteImage: petiteImage,
      logoMarque: logoMarque,
      unique: unique,
    );
  }

  Car withDefaultsFrom(Car fallback) {
    return Car(
      id: id,
      nom: nom,
      marque: marque,
      possedee: possedee,
      categorie: categorie ?? fallback.categorie,
      securite: securite ?? fallback.securite,
      style: style ?? fallback.style,
      nombrePlaces: nombrePlaces ?? fallback.nombrePlaces,
      classementRoute: classementRoute ?? fallback.classementRoute,
      classementTerre: classementTerre ?? fallback.classementTerre,
      modeleBase: modeleBase ?? fallback.modeleBase,
      stats: stats ?? fallback.stats,
      image: image ?? fallback.image,
      petiteImage: petiteImage ?? fallback.petiteImage,
      logoMarque: logoMarque ?? fallback.logoMarque,
      unique: fallback.unique,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'nom': nom,
    'marque': marque,
    'possédée': possedee,
    'categorie': categorie,
    'securite': securite,
    'style': style,
    'nombrePlaces': nombrePlaces,
    'classementRoute': classementRoute,
    'classementTerre': classementTerre,
    'modeleBase': modeleBase,
    'stats': stats?.toJson(),
    'image': image,
    'petiteImage': petiteImage,
    'logoMarque': logoMarque,
    'unique': unique,
  };

  factory Car.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'];
    return Car(
      id: json['id'] as String,
      nom: json['nom'] as String,
      marque: json['marque'] as String,
      possedee: json['possédée'] as bool? ?? false,
      categorie: json['categorie'] as String?,
      securite: json['securite'] as String?,
      style: json['style'] as String?,
      nombrePlaces: json['nombrePlaces'] as int?,
      classementRoute: json['classementRoute'] as int?,
      classementTerre: json['classementTerre'] as int?,
      modeleBase: json['modeleBase'] as String?,
      stats: statsJson == null ? null : CarStats.fromJson(Map<String, dynamic>.from(statsJson as Map)),
      image: json['image'] as String?,
      petiteImage: json['petiteImage'] as String?,
      logoMarque: json['logoMarque'] as String?,
      unique: json['unique'] as bool? ?? false,
    );
  }
}

class CarStats {
  const CarStats({this.vitesse, this.acceleration, this.adherenceAsphalte, this.adherenceTerre, this.robustesse})
    : assert(vitesse == null || (vitesse >= 1 && vitesse <= 10)),
      assert(acceleration == null || (acceleration >= 1 && acceleration <= 10)),
      assert(adherenceAsphalte == null || (adherenceAsphalte >= 1 && adherenceAsphalte <= 10)),
      assert(adherenceTerre == null || (adherenceTerre >= 1 && adherenceTerre <= 10)),
      assert(robustesse == null || (robustesse >= 1 && robustesse <= 10));

  final double? vitesse;
  final double? acceleration;
  final double? adherenceAsphalte;
  final double? adherenceTerre;
  final double? robustesse;

  Map<String, Object?> toJson() => {
    'vitesse': vitesse,
    'acceleration': acceleration,
    'adherenceAsphalte': adherenceAsphalte,
    'adherenceTerre': adherenceTerre,
    'robustesse': robustesse,
  };

  factory CarStats.fromJson(Map<String, dynamic> json) {
    return CarStats(
      vitesse: (json['vitesse'] as num?)?.toDouble(),
      acceleration: (json['acceleration'] as num?)?.toDouble(),
      adherenceAsphalte: (json['adherenceAsphalte'] as num?)?.toDouble(),
      adherenceTerre: (json['adherenceTerre'] as num?)?.toDouble(),
      robustesse: (json['robustesse'] as num?)?.toDouble(),
    );
  }
}
