class Enclosure {
  final String id;
  final String cadastralRef;
  final String polygonNumber;
  final String enclosureNumber;
  final String sigpacUse;

  Enclosure({
    required this.id,
    required this.cadastralRef,
    required this.polygonNumber,
    required this.enclosureNumber,
    required this.sigpacUse,
  });

  factory Enclosure.fromMap(Map<String, dynamic> map) {
    return Enclosure(
      id: map['id_recinto_sigpac'] as String,
      cadastralRef: map['ref_catastral'] as String,
      polygonNumber: map['num_poligono'] as String,
      enclosureNumber: map['num_recinto'] as String,
      sigpacUse: map['uso_sigpac'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_recinto_sigpac': id,
      'ref_catastral': cadastralRef,
      'num_poligono': polygonNumber,
      'num_recinto' : enclosureNumber,
      'uso_sigpac': sigpacUse,
    };
  }
}
