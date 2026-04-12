import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:geolocator/geolocator.dart';

import 'olivo_service.dart';
import 'olivo_model.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({Key? key}) : super(key: key);

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool showInfoCard = false;
  bool planeFound = false;

  final OlivoService _olivoService = OlivoService();
  Olivo? _olivoSeleccionado;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void _resetUI() {
    setState(() {
      showInfoCard = false;
      planeFound = false;
      _olivoSeleccionado = null;
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

      try{
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

        Olivo? olivoEncontrado = _olivoService.obtenerOlivoMasCercano(position);

        if (olivoEncontrado != null){
          setState(() {
            planeFound = true;
            _olivoSeleccionado = olivoEncontrado;
            showInfoCard = true;
          });
        }
      } catch (e) {
        debugPrint("Error obteniendo GPS: $e");
      }

    };
  }


  Widget viewCard() {
    if (showInfoCard && _olivoSeleccionado != null) {

      bool esCritico = _olivoSeleccionado!.tienePlaga || _olivoSeleccionado!.humedadSuelo < 0.15;
      Color colorEstado = esCritico ? Colors.red : Colors.green;
      String textoEstado = esCritico ? "ATENCIÓN REQUERIDA" : "ESTADO ÓPTIMO";


      String fechaTexto = "Sin datos";
      if (_olivoSeleccionado!.ultimaFechaTratamiento != null) {
        DateTime f = _olivoSeleccionado!.ultimaFechaTratamiento!;
        fechaTexto = "${f.day}/${f.month}/${f.year}";
      }

      return Positioned(
        bottom: 30, left: 20, right: 20,
        child: Card(
          elevation: 10,
          color: Colors.white.withOpacity(0.98),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorEstado, width: 2)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      backgroundColor: colorEstado.withOpacity(0.2),
                      avatar: Icon(Icons.park, color: colorEstado),
                      label: Text("${_olivoSeleccionado!.id}: $textoEstado", style: TextStyle(fontWeight: FontWeight.bold, color: colorEstado)),
                    ),
                    CloseButton(onPressed: _resetUI),
                  ],
                ),
                const Divider(),

                _buildRowInfo("Variedad:", _olivoSeleccionado!.variedad),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Humedad Suelo:", style: TextStyle(color: Colors.grey)),
                    Text(
                        "${(_olivoSeleccionado!.humedadSuelo * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _olivoSeleccionado!.humedadSuelo < 0.15 ? Colors.red : Colors.black
                        )
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history, size: 16, color: Colors.blue),
                          SizedBox(width: 5),
                          Text("Último Tratamiento:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Tipo: ${_olivoSeleccionado!.ultimoTratamiento}"),
                      Text("Fecha: $fechaTexto", style: const TextStyle(fontSize: 12, color: Colors.grey)),

                      const SizedBox(height: 5),

                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade300)),
                          onPressed: () => _mostrarDialogoTratamiento(context),
                          child: const Text("Añadir Nuevo Tratamiento", style: TextStyle(fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Registrar Plaga", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _olivoSeleccionado!.tienePlaga,
                  activeColor: Colors.red,
                  onChanged: (bool valor) {
                    setState(() {
                      _olivoSeleccionado!.tienePlaga = valor;
                      _olivoService.actualizarEstadoPlaga(_olivoSeleccionado!.id, valor);
                    });
                  },
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                    icon: const Icon(Icons.water_drop, color: Colors.white),
                    label: const Text("Registrar Riego Manual", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      setState(() {
                        _olivoSeleccionado!.humedadSuelo = 1.0;
                        _olivoService.actualizarEstadoHumedad(_olivoSeleccionado!.id, 1.0);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('💧 Riego registrado'), backgroundColor: Colors.blue)
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return _buildScanningMessage(); // Tu mensaje de búsqueda
    }
  }

  Widget _buildRowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanningMessage() {
    return Positioned(
      top: 20, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: const Text("Buscando olivo cercano...", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _mostrarDialogoTratamiento(BuildContext context) {
    final TextEditingController _textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuevo Tratamiento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Escribe el tipo de tratamiento aplicado hoy (ej: Cobre, Abono, Poda):"),
              const SizedBox(height: 10),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Tipo de tratamiento",
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancelar
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  setState(() {
                    // Actualizamos la BBDD simulada
                    _olivoService.registrarTratamiento(
                        _olivoSeleccionado!.id,
                        _textController.text
                    );

                    // Actualizamos el objeto local para verlo al instante
                    _olivoSeleccionado!.ultimoTratamiento = _textController.text;
                    _olivoSeleccionado!.ultimaFechaTratamiento = DateTime.now();
                  });
                  Navigator.pop(context); // Cerrar diálogo
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}