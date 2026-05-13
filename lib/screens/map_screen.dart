import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String? _lastEnclosureId;

  @override
  void initState() {
    super.initState();
    LocationService.instance.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: LocationService.instance,
        builder: (context, child) {
          final pos = LocationService.instance.currentPosition;
          
          if (pos == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Actualizamos la información de la base de datos de forma modular
          _updateDatabaseContext(pos.latitude, pos.longitude);

          final db = DatabaseService.instance;
          final enclosure = db.currentEnclosure;
          final olives = db.olives;

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(pos.latitude, pos.longitude),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                // Usamos el servicio WMTS del IGN para evitar el error de bbox
                urlTemplate: 'https://www.ign.es/wmts/pnoa-ma?layer=OI.OrthoimageCoverage&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image/jpeg&TileMatrix={z}&TileCol={x}&TileRow={y}',
                userAgentPackageName: 'com.example.tfg',
              ),
              
              if (enclosure != null && enclosure.coordinates.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: enclosure.coordinates
                          .map((c) => LatLng(c.latitude, c.longitude))
                          .toList(),
                      color: Colors.green.withValues(alpha: 0.3),
                      borderStrokeWidth: 3,
                      borderColor: Colors.green,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
                  ...olives.map((olive) => Marker(
                    point: LatLng(olive.latitude, olive.longitude),
                    width: 20,
                    height: 20,
                    child: const Icon(Icons.park, color: Colors.green, size: 15),
                  )),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fitEnclosure,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }

  /// Función idéntica a LivePositionScreen para mantener la consistencia
  Future<void> _updateDatabaseContext(double lat, double lng) async {
    final db = DatabaseService.instance;

    // 1. Buscamos el recinto
    final enclosure = await db.fetchEnclosureByCoordinates(lat, lng);
    
    // Solo actuamos si el recinto ha cambiado
    if (enclosure != null) {
      if (enclosure.id != _lastEnclosureId) {
        setState(() {
          _lastEnclosureId = enclosure.id;
        });
        // Si el recinto es nuevo, ajustamos la cámara al polígono
        _fitEnclosure();
      }
    } else {
      // Si salimos de un recinto, limpiamos el estado
      if (_lastEnclosureId != null) {
        setState(() {
          _lastEnclosureId = null;
        });
      }
    }
  }

  void _fitEnclosure() {
    final enclosure = DatabaseService.instance.currentEnclosure;
    if (enclosure != null && enclosure.coordinates.isNotEmpty) {
      final min = enclosure.minBounds;
      final max = enclosure.maxBounds;
      
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(min.latitude, min.longitude),
            LatLng(max.latitude, max.longitude),
          ),
          padding: const EdgeInsets.all(5), // Menos padding para acercar más la cámara
        ),
      );
    }
  }
}
