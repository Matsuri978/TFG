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
  // LÓGICA DE NEGOCIO
  // ==========================================

  /// Obtiene el usuario actual si hay sesión iniciada, o null.
  ///
  /// Invocada por: ProfileScreen y componentes que necesiten verificar el estado de la sesión.
  User? get currentUser => _supabase.auth.currentUser;

  /// Inicia sesión con correo y contraseña.
  ///
  /// Invocada por: AuthScreen (flujo de login).
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Registra un nuevo usuario y guarda su rol en la tabla 'perfiles'.
  ///
  /// Invocada por: AuthScreen (flujo de registro).
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    // 1. Creamos el usuario en la tabla auth de Supabase
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );

    final user = res.user;

    // 2. Si se ha creado correctamente, insertamos su rol en nuestra tabla 'perfiles'
    if (user != null) {
      await _supabase.from('perfiles').insert({
        'id': user.id,
        'rol': role,
      });
    }
  }

  /// Cierra la sesión actual.
  ///
  /// Invocada por: ProfileScreen (_signOut).
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtiene el rol de un usuario desde la tabla 'perfiles'.
  ///
  /// Invocada por: ProfileScreen (_loadProfileData).
  Future<String> getRole(String userId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', userId)
          .single();
      return response['rol'] as String;
    } catch (e) {
      return 'guest';
    }
  }

  // ==========================================
  // SISTEMA DE PERMISOS
  // ==========================================

  /// Devuelve el mapa completo de permisos según el rol.
  ///
  /// Invocada por: ProfileScreen para listar los permisos en la UI.
  Map<String, bool> getPermissions(String role) {
    bool isFarmer = role == 'agricultor' || role == 'admin';
    bool isTechnician = role == 'tecnico' || role == 'admin';

    return {
      'Ver ubicación y mapas': true,
      'Uso de Escáner AR': true,
      'Registrar Tratamientos': isFarmer || isTechnician,
      'Registrar Observaciones': isTechnician,
      'Modificar datos de Olivos': isTechnician,
    };
  }

  /// Metodo rápido para comprobar si un rol tiene un permiso específico.
  ///
  /// Invocada por: Componentes que necesiten validar acciones específicas.
  bool hasPermission(String role, String action) {
    final permissions = getPermissions(role);
    return permissions[action] ?? false;
  }
}
