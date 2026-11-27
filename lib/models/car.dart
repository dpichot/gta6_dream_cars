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
    this.tracker,
    this.access,
    this.style,
    this.nombrePlaces,
    this.modeleBase,
    this.stats,
    this.unique = false,
    this.dlc,
  }) : assert(classementRoute == null || (classementRoute >= 1 && classementRoute <= 999)),
       assert(classementTerre == null || (classementTerre >= 1 && classementTerre <= 999));

  final String id;
  final String nom;
  final String marque;
  final bool possedee;
  final String? categorie;
  final bool? securite;
  final String? access;
  final String? tracker;
  final String? style;
  final int? nombrePlaces;
  final int? classementRoute;
  final int? classementTerre;
  final String? modeleBase;
  final CarStats? stats;
  final bool unique;
  final String? dlc;

  Car copyWith({bool? possedee}) {
    return Car(
      id: id,
      nom: nom,
      marque: marque,
      possedee: possedee ?? this.possedee,
      categorie: categorie,
      securite: securite,
      tracker: tracker,
      access: access,
      style: style,
      nombrePlaces: nombrePlaces,
      classementRoute: classementRoute,
      classementTerre: classementTerre,
      modeleBase: modeleBase,
      stats: stats,
      unique: unique,
      dlc: dlc,
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
      tracker: tracker ?? fallback.tracker,
      access: access ?? fallback.access,
      style: style ?? fallback.style,
      nombrePlaces: nombrePlaces ?? fallback.nombrePlaces,
      classementRoute: classementRoute ?? fallback.classementRoute,
      classementTerre: classementTerre ?? fallback.classementTerre,
      modeleBase: modeleBase ?? fallback.modeleBase,
      stats: stats ?? fallback.stats,
      unique: fallback.unique,
      dlc: dlc ?? fallback.dlc,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'nom': nom,
    'marque': marque,
    'possédée': possedee,
    'categorie': categorie,
    'securite': securite,
    'tracker': tracker,
    'access': access,
    'style': style,
    'nombrePlaces': nombrePlaces,
    'classementRoute': classementRoute,
    'classementTerre': classementTerre,
    'modeleBase': modeleBase,
    'stats': stats?.toJson(),
    'unique': unique,
    'dlc': dlc,
  };

  factory Car.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'];
    return Car(
      id: json['id'] as String,
      nom: json['nom'] as String,
      marque: json['marque'] as String,
      possedee: json['possédée'] as bool? ?? false,
      categorie: json['categorie'] as String?,
      securite: json['securite'] as bool?,
      tracker: json['tracker'] as String?,
      access: json['access'] as String?,
      style: json['style'] as String?,
      nombrePlaces: json['nombrePlaces'] as int?,
      classementRoute: json['classementRoute'] as int?,
      classementTerre: json['classementTerre'] as int?,
      modeleBase: json['modeleBase'] as String?,
      stats: statsJson == null ? null : CarStats.fromJson(Map<String, dynamic>.from(statsJson as Map)),
      unique: json['unique'] as bool? ?? false,
      dlc: json['dlc'] as String?,
    );
  }
}

class CarStats {
  const CarStats({this.vitesse, this.acceleration, this.adherenceAsphalte, this.adherenceTerre, this.robustesse})
    : assert(vitesse == null || (vitesse >= 0.1 && vitesse <= 10)),
      assert(acceleration == null || (acceleration >= 0.1 && acceleration <= 10)),
      assert(adherenceAsphalte == null || (adherenceAsphalte >= 0.1 && adherenceAsphalte <= 10)),
      assert(adherenceTerre == null || (adherenceTerre >= 0.1 && adherenceTerre <= 10)),
      assert(robustesse == null || (robustesse >= 0.1 && robustesse <= 10));

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
