class Olivo {
  final String id;           // Identificador (ej: "OLIVO-45")
  final double latitud;      // Coordenadas GPS reales
  final double longitud;

  // Datos modificables (Estado)
  String variedad;           // Picual, Arbequina...
  double produccionKg;       // Cosecha anterior
  bool tienePlaga;           // Para la esfera visual (Verde/Rojo)
  double humedadSuelo;       // 0.0 a 1.0 (Para alertas)
  String ultimoTratamiento;  // tipo
  DateTime? ultimaFechaTratamiento; // Fecha

  Olivo({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.variedad,
    required this.produccionKg,
    this.tienePlaga = false,
    this.humedadSuelo = 0.5,
    this.ultimoTratamiento = "Ninguno",
    this.ultimaFechaTratamiento,
  });
}