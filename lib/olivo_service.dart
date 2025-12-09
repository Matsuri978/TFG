import 'package:geolocator/geolocator.dart';
import 'olivo_model.dart';

class OlivoService {

  final List<Olivo> _bbdd = [
    Olivo(
      id: "OLIVO-001",
      latitud: 37.787197,
      longitud: -3.777789,
      variedad: "Picual",
      produccionKg: 45.0,
      tienePlaga: true,
      humedadSuelo: 0.2,
    ),
    Olivo(
      id: "OLIVO-002",
      latitud: 37.787192,
      longitud: -3.777810,
      variedad: "Hojiblanca",
      produccionKg: 32.5,
      tienePlaga: false,
      humedadSuelo: 0.6,
      ultimoTratamiento: "Poda de formación",
      ultimaFechaTratamiento: DateTime(2023, 11, 10),
    ),
    Olivo(
        id: "OLIVO-003",
        latitud: 37.787116,
        longitud: -3.777736,
        variedad: "Arbequina",
        produccionKg: 45,
        tienePlaga: false,
        humedadSuelo: 0.1,
    )
  ];

  Olivo? obtenerOlivoMasCercano(Position miPosicionActual) {
    double minDistanceFound = 10.0;
    Olivo? closestOlive;

    for (var olivo in _bbdd) {
      double distancia = Geolocator.distanceBetween(
        miPosicionActual.latitude,
        miPosicionActual.longitude,
        olivo.latitud,
        olivo.longitud,
      );


      if (distancia < minDistanceFound) {
        minDistanceFound = distancia;
        closestOlive = olivo;
      }
    }
    return closestOlive;
  }

  void actualizarEstadoPlaga(String id, bool tienePlaga) {
    final index = _bbdd.indexWhere((o) => o.id == id);
    if (index != -1) {
      _bbdd[index].tienePlaga = tienePlaga;
    }
  }

  void actualizarEstadoHumedad(String id, double humedad) {
    final index = _bbdd.indexWhere((o) => o.id == id);
    if (index != -1) {
      _bbdd[index].humedadSuelo = humedad;
    }
  }

  void registrarTratamiento(String id, String tipo) {
    var olivo = _bbdd.firstWhere((o) => o.id == id);
    olivo.ultimoTratamiento = tipo;
    olivo.ultimaFechaTratamiento = DateTime.now();
  }
}