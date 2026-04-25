import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static AuthService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ==========================================
  // MÉTODOS DE NEGOCIO (LÓGICA)
  // ==========================================

  /// Obtiene el usuario actual si hay sesión iniciada, o null.
  User? get currentUser => _supabase.auth.currentUser;

  /// Inicia sesión con correo y contraseña.
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Registra un nuevo usuario y guarda su rol en la tabla 'perfiles'.
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    // 1. Creamos el usuario en la tabla auth de Supabase
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': nombre},
    );

    final user = res.user;

    // 2. Si se ha creado correctamente, insertamos su rol en nuestra tabla 'perfiles'
    if (user != null) {
      await _supabase.from('perfiles').insert({
        'id': user.id,
        'rol': rol,
      });
    }
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtiene el rol de un usuario desde la tabla 'perfiles'.
  Future<String> obtenerRol(String userId) async {
    try {
      final respuesta = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', userId)
          .single();
      return respuesta['rol'] as String;
    } catch (e) {
      return 'invitado'; // Si falla por lo que sea, asumimos menos privilegios
    }
  }

  // ==========================================
  // SISTEMA DE PERMISOS
  // ==========================================

  /// Devuelve el mapa completo de permisos según el rol
  Map<String, bool> obtenerPermisos(String rol) {
    // Mantenemos tu lógica original
    bool esAgri = rol == 'agricultor' || rol == 'admin';
    bool esTec = rol == 'tecnico' || rol == 'admin';

    return {
      'Ver ubicación y mapas': true,
      'Uso de Escáner AR': true,
      'Registrar Tratamientos': esAgri || esTec,
      'Registrar Plagas': esTec,
      'Modificar datos de Olivos': esTec,
    };
  }

  /// Método rápido para comprobar si un rol tiene un permiso específico
  /// Ejemplo de uso: AuthService.instance.tienePermiso('agricultor', 'Registrar Plagas')
  bool tienePermiso(String rol, String accion) {
    final permisos = obtenerPermisos(rol);
    return permisos[accion] ?? false; // Si la acción no existe, por defecto es false
  }
}