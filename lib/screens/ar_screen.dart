import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';

import 'package:arceituna/services/services.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/utils/utils.dart';

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
  void initState() {
    super.initState();
    LocationService.instance.startTracking();
    LocationService.instance.addListener(_checkScanning);
  }

  @override
  void dispose() {
    LocationService.instance.removeListener(_checkScanning);
    arSessionManager?.dispose();
    super.dispose();
  }

  /// Escanea constantemente la posición y orientación para detectar olivos cercanos.
  /// Independiente de la detección de planos de ARCore/ARKit.
  void _checkScanning() {
    if (showInfoCard || planeFound) return;

    final pos = LocationService.instance.currentPosition;
    final heading = LocationService.instance.currentHeading;

    if (pos != null && heading != null) {
      try {
        Olive? oliveFound = getOliveInSight(pos, heading);

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
    }
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
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      showAnimatedGuide: false,
      handleTaps: false,
    );

    arObjectManager!.onInitialize();

    // La lógica de detección se ha movido a _checkScanning para que funcione 
    // independientemente de si se detectan superficies físicas (planos).
    arSessionManager!.onPlaneDetected = (plane) {};
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
          child: const Text("Apunta hacia un olivo cercano...",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
