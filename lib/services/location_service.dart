import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService extends ChangeNotifier {
  // ==========================================
  // PATRÓN SINGLETON (Igual que en AuthService)
  // ==========================================
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  static LocationService get instance => _instance;

  // ==========================================
  // ESTADO Y VARIABLES
  // ==========================================
  Position? _currentPosition;
  Placemark? _currentPlace;
  String _statusMessage = 'Inicializando...';
  StreamSubscription<Position>? _positionStreamSubscription;

  // Getters para acceder desde la UI
  Position? get currentPosition => _currentPosition;
  Placemark? get currentPlace => _currentPlace;
  String get statusMessage => _statusMessage;

  // ==========================================
  // MÉTODOS DE NEGOCIO (LÓGICA)
  // ==========================================

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = 'El servicio de ubicación está desactivado.';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _statusMessage = 'Permiso de ubicación denegado.';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _statusMessage = 'Permiso de ubicación denegado permanentemente.';
      notifyListeners();
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _currentPlace = placemarks.first;
      } catch (e) {
        _currentPlace = null;
      }

      _currentPosition = position;
      _statusMessage = 'Ubicación actualizada';

      // Avisa a ListenableBuilder para que redibuje la pantalla
      notifyListeners();
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}