import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ==========================================
  // ESTADO LOCAL (CACHE)
  // ==========================================
  List<Olive> _olives = [];
  Enclosure? _currentEnclosure;

  List<Olive> get olives => _olives;
  Enclosure? get currentEnclosure => _currentEnclosure;

  // ==========================================
  // OLIVOS
  // ==========================================

  /// Obtiene y actualiza la lista local de olivos para un recinto específico
  Future<void> _updateOlivesByEnclosure(String enclosureId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('olivos')
          .select()
          .eq('id_recinto_sigpac', enclosureId);

      _olives = response.map((json) => Olive.fromMap(json)).toList();
    } catch (e) {
      print('Error al actualizar olivos: $e');
      _olives = [];
    }
  }

  // ==========================================
  // RECINTOS
  // ==========================================

  /// Obtiene el recinto por coordenadas y actualiza los olivos si el recinto cambia
  Future<Enclosure?> getEnclosureByCoordinates(double lat, double lng) async {
    try {
      final response = await _supabase
          .from('recintos')
          .select()
          .filter('geom', 'st_contains', 'POINT($lng $lat)')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        Enclosure newEnclosure = Enclosure.fromMap(response);

        // Si el recinto es diferente al guardado
        if (newEnclosure.id != _currentEnclosure?.id) {
          print('Cambio de recinto detectado: ${newEnclosure.id}. Actualizando olivos...');
          _currentEnclosure = newEnclosure;
          await _updateOlivesByEnclosure(newEnclosure.id);
        }
        return newEnclosure;
      }
      
      return null;
    } catch (e) {
      print('Error al obtener recinto: $e');
      return null;
    }
  }

  // ==========================================
  // REGISTROS (Tratamientos y Observaciones)
  // ==========================================

  Future<List<Map<String, dynamic>>> getTreatmentsByOlive(int oliveId) async {
    try {
      return await _supabase
          .from('registro_tratamientos')
          .select()
          .eq('cod_olivo', oliveId)
          .order('fecha_tratamiento', ascending: false);
    } catch (e) {
      print('Error al obtener tratamientos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getObservationsByOlive(int oliveId) async {
    try {
      return await _supabase
          .from('registro_observaciones')
          .select()
          .eq('cod_olivo', oliveId)
          .order('fecha_observacion', ascending: false);
    } catch (e) {
      print('Error al obtener observaciones: $e');
      return [];
    }
  }
}
