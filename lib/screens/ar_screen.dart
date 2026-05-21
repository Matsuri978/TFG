import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/utils/utils.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool showInfoCard = false;
  bool planeFound = false;

  Olive? _selectedOlive;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  /// Reinicia los estados de la interfaz AR.
  ///
  /// Invocada por: Cierre de la tarjeta de información del olivo.
  void _resetUI() {
    setState(() {
      showInfoCard = false;
      planeFound = false;
      _selectedOlive = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          viewCard(),
        ],
      ),
    );
  }

  /// Callback que se ejecuta cuando la vista AR se ha creado correctamente.
  ///
  /// Inicializa los managers de sesión y objetos.
  ///
  /// Invocada por: Widget ARView.
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    dynamic anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: false,
      showAnimatedGuide: true,
      handleTaps: false,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneDetected = (plane) async {
      if (planeFound) return;

      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        // Buscamos el olivo más cercano de los cargados en el servicio
        Olive? oliveFound = _getClosestOlive(position);

        if (oliveFound != null) {
          setState(() {
            planeFound = true;
            _selectedOlive = oliveFound;
            showInfoCard = true;
          });
        }
      } catch (e) {
        // Error silenciado
      }
    };
  }

  /// Busca el olivo más cercano a la posición actual dentro de un radio de 10 metros.
  ///
  /// Invocada por: onPlaneDetected al detectar una superficie.
  Olive? _getClosestOlive(Position currentPos) {
    final olives = DatabaseService.instance.olives;
    if (olives.isEmpty) return null;

    Olive? closest;
    double minDistance = 10.0; // metros

    for (var olive in olives) {
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        olive.latitude,
        olive.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closest = olive;
      }
    }
    return closest;
  }

  /// Decide qué componente mostrar sobre la vista AR (tarjeta de info o mensaje de escaneo).
  ///
  /// Invocada por: build() de ARScreen.
  Widget viewCard() {
    if (showInfoCard && _selectedOlive != null) {
      return OliveInfoCard(
        olive: _selectedOlive!,
        onClose: _resetUI,
      );
    } else {
      return _buildScanningMessage();
    }
  }

  /// Construye el mensaje flotante que indica que se está buscando un olivo.
  ///
  /// Invocada por: viewCard().
  Widget _buildScanningMessage() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: const Text("Buscando olivo cercano...",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
