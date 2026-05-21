class Olive {
  final int id;
  final String enclosureId;
  final String? variety;
  final String? healthStatus;
  final double latitude;
  final double longitude;

  Olive({
    required this.id,
    required this.enclosureId,
    this.variety,
    this.healthStatus,
    required this.latitude,
    required this.longitude,
  });

  /// Convierte la respuesta de Supabase a un objeto Olive.
  factory Olive.fromMap(Map<String, dynamic> map) {
    double lat = 0.0;
    double lng = 0.0;

    if (map['geom'] != null) {
      final geom = map['geom'];

      // Si Supabase devuelve GeoJSON (objeto)
      if (geom is Map && geom['coordinates'] != null) {
        lng = (geom['coordinates'][0] as num).toDouble();
        lat = (geom['coordinates'][1] as num).toDouble();
      }
      // Si devuelve WKT String "POINT(lng lat)"
      else if (geom is String) {
        final coords = geom
            .replaceAll('POINT(', '')
            .replaceAll(')', '')
            .trim()
            .split(' ');
        if (coords.length >= 2) {
          lng = double.tryParse(coords[0]) ?? 0.0;
          lat = double.tryParse(coords[1]) ?? 0.0;
        }
      }
    }

    return Olive(
      id: map['cod_olivo'] as int,
      enclosureId: map['id_recinto_sigpac'] as String,
      variety: map['variedad'] as String?,
      healthStatus: map['estado_salud'] as String?,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Convierte el objeto Olive a Map para Supabase.
  Map<String, dynamic> toMap() {
    return {
      'cod_olivo': id,
      'id_recinto_sigpac': enclosureId,
      'variedad': variety,
      'estado_salud': healthStatus,
      'geom': 'POINT($longitude $latitude)',
    };
  }

  /// Devuelve el texto formateado de las coordenadas.
  String get coordinatesText =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
