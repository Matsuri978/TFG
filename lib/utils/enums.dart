import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/screens/screens.dart';

/// Opciones del menú lateral de la aplicación
enum MenuOption {
  profile(
    menuTitle: 'Perfil',
    appBarTitle: 'Perfil',
    icon: Icons.person,
    screen: ProfileScreen(),
  ),
  home(
    menuTitle: 'Inicio',
    appBarTitle: 'Ubicación en tiempo real',
    icon: Icons.location_on_outlined,
    screen: LivePositionScreen(),
  ),
  arScanner(
    menuTitle: 'Escáner AR',
    appBarTitle: 'Escáner de Realidad Aumentada',
    icon: Icons.qr_code_scanner,
    screen: ARScreen(),
  ),
  map(
    menuTitle: 'Mapa',
    appBarTitle: 'Mapa del Recinto',
    icon: Icons.map,
    screen: MapScreen(),
  );

  final String menuTitle;
  final String appBarTitle;
  final IconData icon;
  final Widget screen;

  const MenuOption({
    required this.menuTitle,
    required this.appBarTitle,
    required this.icon,
    required this.screen,
  });
}

/// Secciones de información detallada en la pantalla de posición en vivo
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
  ),

  sigpac(
    title: "SigPac",
    icon: Icons.map_outlined,
    fieldsBuilder: _buildSigpacFields,
  );

  final String title;
  final IconData icon;
  final List<Widget> Function(Position?, Placemark?) fieldsBuilder;

  const InfoSection({
    required this.title,
    required this.icon,
    required this.fieldsBuilder,
  });

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

// --- Helpers para InfoSection ---

List<Widget> _buildCoordinateFields(Position? pos, Placemark? place) {
  return [
    _row("Longitud", pos?.longitude.toStringAsFixed(6)),
    _row("Latitud", pos?.latitude.toStringAsFixed(6)),
    _row("Altitud", "${pos?.altitude.toStringAsFixed(2)} m"),
    _row("Precisión", "${pos?.accuracy.toStringAsFixed(2)} m"),
  ];
}

List<Widget> _buildAddressFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;
  
  String? provinceName = db.currentProvince?['nombre'];
  if (provinceName != null && provinceName.isNotEmpty) {
    provinceName = provinceName[0].toUpperCase() + provinceName.substring(1).toLowerCase();
  }

  String? municipalityName = db.currentMunicipality?['nombre'];
  if ( municipalityName != null && municipalityName.isNotEmpty ) {
    municipalityName = municipalityName[0].toUpperCase() + municipalityName.substring(1).toLowerCase();
  }

  return [
    _row("País", place?.country),
    _row("C. Autónoma", place?.administrativeArea),
    _row("Provincia", provinceName ?? place?.subAdministrativeArea),
    _row("Municipio", municipalityName ?? place?.locality),
    _row("Calle", place?.street),
    _row("Edificio", place?.name),
    _row("Código postal", place?.postalCode),
  ];
}

List<Widget> _buildSigpacFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;

  return [
    _row("Provincia", db.currentProvince != null 
        ? "${db.currentProvince!['nombre']} (${db.currentProvince!['codigo_ine_prov']}) "
        : null),
    _row("Municipio", db.currentMunicipality != null 
        ? "${db.currentMunicipality!['nombre']} (${db.currentMunicipality!['num_municipio']}) "
        : null),
    _row("Num. Parcela", db.currentParcel?['num_parcela']?.toString()),
    _row("Recinto", db.currentEnclosure != null 
        ? "${db.currentEnclosure!.enclosureNumber} (${db.currentEnclosure!.polygonNumber}) "
        : null),
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
