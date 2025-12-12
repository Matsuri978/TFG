import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool showInfoCard = false;
  bool planeFound = false;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void resetUI() {
    setState(() {
      showInfoCard = false;
      planeFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector Automático'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
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

    arSessionManager!.onPlaneDetected = (plane) {
      if (planeFound) return;

      setState(() {
        planeFound = true;
        showInfoCard = true;
      });
    };
  }


  Widget viewCard() {
    if (showInfoCard) {
      return Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Card(
          elevation: 10,
          color: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "¡Superficie Encontrada!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    CloseButton(
                      onPressed: () {
                        resetUI();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  "Información del objeto:\nEl sistema ha detectado el plano correctamente.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Mueve el móvil lentamente para detectar el suelo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
  }
}