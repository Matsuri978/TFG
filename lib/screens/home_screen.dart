import 'package:flutter/material.dart';

import 'package:tfg/screens/screens.dart';

enum OpcionMenu {
  perfil(
    tituloMenu: 'Perfil',
    tituloAppBar: 'Perfil',
    icono: Icons.person,
    pantalla: PerfilScreen(), // Ahora es una sección más
  ),
  inicio(
    tituloMenu: 'Inicio',
    tituloAppBar: 'Ubicación en tiempo real',
    icono: Icons.location_on_outlined,
    pantalla: LivePositionScreen(),
  ),
  escanerAR(
    tituloMenu: 'Escáner AR',
    tituloAppBar: 'Escáner de Realidad Aumentada',
    icono: Icons.qr_code_scanner,
    pantalla: ARScreen(),
  );

  final String tituloMenu;
  final String tituloAppBar;
  final IconData icono;
  final Widget pantalla;

  const OpcionMenu({
    required this.tituloMenu,
    required this.tituloAppBar,
    required this.icono,
    required this.pantalla,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 2. Controlamos el estado directamente con el enum en lugar de un número
  OpcionMenu _opcionActual = OpcionMenu.inicio;

  void _cambiarPantalla(OpcionMenu opcion) {
    setState(() {
      _opcionActual = opcion;
    });
    // Cerramos el menú lateral al seleccionar una opción
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: false,

        title: Text(
          _opcionActual.tituloAppBar,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            InkWell(
              onTap: () => _cambiarPantalla(OpcionMenu.perfil),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
                decoration: BoxDecoration(
                  color: _opcionActual == OpcionMenu.perfil ? Colors.green.shade100 : Colors.green.shade50,
                  border: Border(bottom: BorderSide(color: Colors.green.shade200)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green.shade700,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...OpcionMenu.values.where((opcion) => opcion != OpcionMenu.perfil).map((opcion) {
              return ListTile(
                leading: Icon(opcion.icono, size: 30, color: Colors.black87),
                title: Text(opcion.tituloMenu, style: const TextStyle(fontSize: 18)),
                selected: _opcionActual == opcion,
                selectedTileColor: Colors.green.shade100,
                onTap: () => _cambiarPantalla(opcion),
              );
            }),
          ],
        ),
      ),
      // 4. Mostramos la pantalla leyendo directamente el widget guardado en el enum
      body: _opcionActual.pantalla,
    );
  }
}