import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';

// ==========================================
// CONSTANTES DE AR / DETECCIÓN
// ==========================================
const double oliveDetectionRadius = 5.0; // metros
const double oliveFovDegrees = 30.0; // Grados de apertura del visor

/// Comprueba si un punto (lat, lng) está dentro de un polígono definido por una lista de coordenadas.
/// Implementación robusta de Ray Casting usando 3 rayos para evitar anomalías en vértices o aristas.
///
/// [min] y [max] son opcionales y representan la Bounding Box del polígono para optimización previa.
bool isPointInPolygon(double lat, double lng, List<Coordinate> polygon,
    {Coordinate? min, Coordinate? max}) {
  if (polygon.isEmpty) return false;

  // 0. OPTIMIZACIÓN POR BOUNDING BOX (AABB)
  // Si el punto está fuera de la caja delimitadora, no puede estar en el polígono.
  // Esta comprobación de 4 comparaciones es mucho más rápida que el Ray Casting.
  if (min != null && max != null) {
    if (lat < min.latitude ||
        lat > max.latitude ||
        lng < min.longitude ||
        lng > max.longitude) {
      return false;
    }
  }

  // 1. Rayo Horizontal (Hacia la derecha)
  bool horizontalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    if (((polygon[i].latitude > lat) != (polygon[j].latitude > lat)) &&
        (lng < (polygon[j].longitude - polygon[i].longitude) * (lat - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
      horizontalInside = !horizontalInside;
    }
  }

  // 2. Rayo Vertical (Hacia arriba)
  bool verticalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    if (((polygon[i].longitude > lng) != (polygon[j].longitude > lng)) &&
        (lat < (polygon[j].latitude - polygon[i].latitude) * (lng - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) + polygon[i].latitude)) {
      verticalInside = !verticalInside;
    }
  }

  // 3. Si ambos coinciden, el resultado es altamente fiable
  if (horizontalInside == verticalInside) return horizontalInside;

  // 4. Caso anómalo: Lanzamos un tercer rayo diagonal (45 grados) para desempatar
  // Esto ocurre si el punto cae justo en una arista o vértice problemático para un eje.
  bool diagonalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    // Transformación simple para simular rayo diagonal: comparamos (lat+lng)
    double pointSum = lat + lng;
    double piSum = polygon[i].latitude + polygon[i].longitude;
    double pjSum = polygon[j].latitude + polygon[j].longitude;

    if (((piSum > pointSum) != (pjSum > pointSum)) &&
        (lat - lng < (polygon[j].latitude - polygon[j].longitude - (polygon[i].latitude - polygon[i].longitude)) * 
        (pointSum - piSum) / (pjSum - piSum) + (polygon[i].latitude - polygon[i].longitude))) {
      diagonalInside = !diagonalInside;
    }
  }

  return diagonalInside;
}

/// Busca el olivo más cercano a la posición actual que esté dentro del campo de visión.
///
/// Invocada por: ARScreen.
Olive? getOliveInSight(Position currentPos, double? heading) {
  final olives = DatabaseService.instance.olives;
  if (olives.isEmpty || heading == null) return null;

  Olive? closest;
  double minDistance = oliveDetectionRadius;

  for (var olive in olives) {
    // 1. Calcular distancia
    double distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      olive.location.latitude,
      olive.location.longitude,
    );

    if (distance < minDistance) {
      // 2. Calcular Bearing (dirección hacia el olivo)
      double bearing = Geolocator.bearingBetween(
        currentPos.latitude,
        currentPos.longitude,
        olive.location.latitude,
        olive.location.longitude,
      );

      // Normalizar bearing a 0-360
      double bearing360 = (bearing + 360) % 360;

      // 3. Comprobar si está dentro del FOV (rango de visión)
      if (isWithinFOV(heading, bearing360, oliveFovDegrees)) {
        minDistance = distance;
        closest = olive;
      }
    }
  }
  return closest;
}

/// Determina si un bearing está dentro del rango de visión respecto al heading actual.
bool isWithinFOV(double heading, double bearing, double fov) {
  double diff = (bearing - heading).abs();
  if (diff > 180) diff = 360 - diff;
  return diff <= (fov / 2);
}

/// Formatea una cadena de fecha a formato DD/MM/YYYY.
///
/// Invocada por: OliveHistoryScreen (historial de tratamientos y observaciones).
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final DateTime date = DateTime.parse(dateStr);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  } catch (e) {
    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      if (parts[0].length == 4) return "${parts[2]}/${parts[1]}/${parts[0]}";
      return "${parts[0]}/${parts[1]}/${parts[2]}";
    }
    return dateStr;
  }
}

/// Obtiene el número de días de un mes y año específicos.
///
/// Invocada por: OliveHistoryScreen (filtro de fecha progresivo).
int getDaysInMonth(int? year, int? month) {
  if (month == null) return 31;
  return DateUtils.getDaysInMonth(year ?? DateTime.now().year, month);
}

/// Muestra una fila de información personalizable.
///
/// [isBetween] controla si el valor aparece a continuación (false) o alineado a la derecha (true).
///
/// Invocada por: OliveHistoryScreen y builders de InfoSection (LocationService).
Widget infoRow(
  String label,
  dynamic value, {
  String nullValue = 'N/A',
  bool isBetween = false,
  FontWeight labelWeight = FontWeight.bold,
  FontWeight valueWeight = FontWeight.normal,
  Color? labelColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment:
          isBetween ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      crossAxisAlignment:
          isBetween ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(isBetween ? label : "$label: ",
            style: TextStyle(fontWeight: labelWeight, color: labelColor)),
        if (isBetween)
          Text("${value ?? nullValue}",
              style: TextStyle(fontWeight: valueWeight))
        else
          Expanded(
              child: Text("${value ?? nullValue}",
                  style: TextStyle(fontWeight: valueWeight))),
      ],
    ),
  );
}

/// Builders para las secciones de información de ubicación (usados en InfoSection).
///
/// Invocadas por: InfoSection (enums.dart) para construir tarjetas de ubicación.
List<Widget> buildCoordinateFields(Position? pos, Placemark? place) {
  return [
    infoRow("Longitud", pos?.longitude.toStringAsFixed(6),
        isBetween: true, nullValue: "-"),
    infoRow("Latitud", pos?.latitude.toStringAsFixed(6),
        isBetween: true, nullValue: "-"),
    infoRow("Altitud", "${pos?.altitude.toStringAsFixed(2)} m",
        isBetween: true, nullValue: "-"),
    infoRow("Precisión", "${pos?.accuracy.toStringAsFixed(2)} m",
        isBetween: true, nullValue: "-"),
  ];
}

List<Widget> buildAddressFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;
  final province = db.currentProvince?['nombre']?.toString().capitalize();
  final municipality =
      db.currentMunicipality?['nombre']?.toString().capitalize();

  return [
    infoRow("País", place?.country, isBetween: true, nullValue: "-"),
    infoRow("C. Autónoma", place?.administrativeArea,
        isBetween: true, nullValue: "-"),
    infoRow("Provincia", province ?? place?.subAdministrativeArea,
        isBetween: true, nullValue: "-"),
    infoRow("Municipio", municipality ?? place?.locality,
        isBetween: true, nullValue: "-"),
    infoRow("Calle", place?.street, isBetween: true, nullValue: "-"),
    infoRow("Edificio", place?.name, isBetween: true, nullValue: "-"),
    infoRow("Código postal", place?.postalCode, isBetween: true, nullValue: "-"),
  ];
}

List<Widget> buildSigpacFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;
  final provinceData = db.currentProvince;
  final municipalityData = db.currentMunicipality;

  return [
    infoRow(
        "Provincia",
        provinceData != null
            ? "${provinceData['nombre']} (${provinceData['codigo_ine_prov']})"
            : null,
        isBetween: true,
        nullValue: "-"),
    infoRow(
        "Municipio",
        municipalityData != null
            ? "${municipalityData['nombre']} (${municipalityData['num_municipio']})"
            : null,
        isBetween: true,
        nullValue: "-"),
    infoRow("Num. Parcela", db.currentParcel?['num_parcela']?.toString(),
        isBetween: true, nullValue: "-"),
    infoRow(
        "Recinto",
        db.currentEnclosure != null
            ? "${db.currentEnclosure!.enclosureNumber} (${db.currentEnclosure!.polygonNumber})"
            : null,
        isBetween: true,
        nullValue: "-"),
  ];
}

/// Muestra una tarjeta de información con icono, título y valor.
///
/// Invocada por: ProfileScreen para mostrar datos del usuario y rol.
Widget infoCard({
  required String title,
  required String value,
  required IconData icon,
  Color iconColor = Colors.green,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 2,
    child: ListTile(
      leading: Icon(icon, color: iconColor),
      title:
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    ),
  );
}

/// Muestra un SnackBar rápido en la pantalla.
///
/// Invocada por: AuthScreen para mostrar errores de autenticación o mensajes de éxito.
void showMessage(BuildContext context, String message,
    {bool isError = false, bool neutral = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          neutral ? null : (isError ? Colors.red : Colors.green.shade700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Muestra un diálogo de confirmación estándar.
///
/// Invocada por: ProfileScreen (Cerrar sesión) y WelcomeScreen (Continuar como invitado).
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  Color confirmColor = Colors.red,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText, style: const TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Extensión para capitalizar la primera letra de un String.
///
/// Invocada por: ProfileScreen (Rol) y builders de dirección (Provincia/Municipio).
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

/// Selector desplegable genérico con estilo personalizado y opción "Todos".
///
/// Invocada por: OliveHistoryScreen (filtros de fecha, tipo y estado).
Widget buildSimpleDropdown<T>({
  required String hint,
  required T? value,
  required List<T> items,
  required void Function(T?) onChanged,
  required String Function(T) itemText,
  bool enabled = true,
  bool showAllOption = false,
  String? allOptionLabel,
  String? Function(T?)? validator,
}) {
  return Opacity(
    opacity: enabled ? 1.0 : 0.5,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: hint,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(showAllOption ? (allOptionLabel ?? "Todos") : hint,
              style: TextStyle(
                  fontSize: 16,
                  color: showAllOption ? Colors.black : Colors.grey)),
        ),
        ...items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemText(item), style: const TextStyle(fontSize: 16)),
          );
        }),
      ],
    ),
  );
}
