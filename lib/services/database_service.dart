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
  List<Olive> olives = [];
  Enclosure? currentEnclosure;
  Map<String, dynamic>? currentParcel;
  Map<String, dynamic>? currentMunicipality;
  Map<String, dynamic>? currentProvince;

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

      olives = response.map((json) => Olive.fromMap(json)).toList();
    } catch (e) {
      print('Error al actualizar olivos: $e');
      olives = [];
    }
  }

  // ==========================================
  // RECINTOS Y UBICACIÓN (MODULAR)
  // ==========================================

  /// 1. Obtiene el recinto por coordenadas llamando a la función RPC de Postgres
  Future<Enclosure?> fetchEnclosureByCoordinates(double lat, double lng) async {
    try {
      // Llamamos a la función RPC creada en Supabase (get_enclosure_by_point)
      final response = await _supabase.rpc('get_enclosure_by_point', params: {
        'lng_param': lng,
        'lat_param': lat,
      }).maybeSingle();

      if (response != null) {
        Enclosure newEnclosure = Enclosure.fromMap(response);

        // SOLO si el ID es diferente al que ya tenemos guardado
        if (currentEnclosure?.id != newEnclosure.id) {
          print('Nuevo recinto detectado: ${newEnclosure.id}');
          currentEnclosure = newEnclosure;
          await _updateOlivesByEnclosure(newEnclosure.id);
        }
        return currentEnclosure;
      }

      currentEnclosure = null;
      olives = [];
      return null;
    } catch (e) {
      print('Error al obtener recinto (RPC): $e');
      return null;
    }
  }

  /// 2. Obtiene la parcela usando la referencia catastral del recinto
  Future<void> fetchParcelByRef(String cadastralRef) async {
    try {
      currentParcel = await _supabase
          .from('parcelas')
          .select()
          .eq('ref_catastral', cadastralRef)
          .maybeSingle();
    } catch (e) {
      print('Error al obtener parcela: $e');
      currentParcel = null;
    }
  }

  /// 3. Obtiene el municipio usando el código de hoja de la parcela
  Future<void> fetchMunicipalityBySheet(String sheetCode) async {
    try {
      currentMunicipality = await _supabase
          .from('municipios')
          .select()
          .eq('codigo_hoja', sheetCode)
          .maybeSingle();
    } catch (e) {
      print('Error al obtener municipio: $e');
      currentMunicipality = null;
    }
  }

  /// 4. Obtiene la provincia usando el código INE del municipio
  Future<void> fetchProvinceByIne(String ineCode) async {
    try {
      currentProvince = await _supabase
          .from('provincias')
          .select()
          .eq('codigo_ine_prov', ineCode)
          .maybeSingle();
    } catch (e) {
      print('Error al obtener provincia: $e');
      currentProvince = null;
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
