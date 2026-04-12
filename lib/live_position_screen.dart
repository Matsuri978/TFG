import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LivePositionScreen extends StatefulWidget {
  const LivePositionScreen({Key? key}) : super(key: key);

  @override
  _LivePositionScreenState createState() => _LivePositionScreenState();
}

class _LivePositionScreenState extends State<LivePositionScreen> {
  Position? _currentPosition;
  Placemark? _currentPlace;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _statusMessage = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _initLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'El servicio de ubicación está desactivado.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Permiso de ubicación denegado.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = 'Permiso de ubicación denegado permanentemente.');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _currentPlace = placemarks.first;
        _statusMessage = 'Ubicación actualizada';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
        body: _currentPosition == null || _currentPlace == null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_statusMessage, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ) : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: InfoSection.values.map(
                  (section) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: section.buildCard(_currentPosition, _currentPlace),
              ),
            ).toList(),
          ),
        )
    );
  }

}
enum InfoSection {
  coordinates(
    title: "Coordenadas",
    icon: Icons.location_searching,
    fieldsBuilder: _buildCoordinateFields,
  ),

  address(
    title: "Dirección",
    icon: Icons.location_on,
    fieldsBuilder: _buildAddressFields,
  );

  final String title;
  final IconData icon;

  /// Método que genera los rows dinámicamente
  final List<Widget> Function(Position?, Placemark?) fieldsBuilder;

  const InfoSection({
    required this.title,
    required this.icon,
    required this.fieldsBuilder,
  });

  /// Método para construir la tarjeta completa
  Widget buildCard(Position? pos, Placemark? place) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...fieldsBuilder(pos, place),
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildCoordinateFields(Position? pos, Placemark? place) {
  return [
    _row("Latitud", pos?.latitude.toStringAsFixed(6)),
    _row("Longitud", pos?.longitude.toStringAsFixed(6)),
    _row("Altitud", "${pos?.altitude.toStringAsFixed(2)} m"),
    _row("Precisión", "${pos?.accuracy.toStringAsFixed(2)} m"),
  ];
}

List<Widget> _buildAddressFields(Position? pos, Placemark? place) {
  return [
    _row("País", place?.country),
    _row("Provincia", place?.administrativeArea),
    _row("Ciudad", place?.locality),
    _row("Barrio", place?.subLocality),
    _row("Calle", place?.street),
    _row("Edificio", place?.name),
    _row("Código postal", place?.postalCode),
  ];
}

Widget _row(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value ?? "-"),
      ],
    ),
  );
}