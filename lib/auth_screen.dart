import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_swipe_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // Controla si estamos en modo Login o Registro
  String _rolSeleccionado = 'agricultor'; // Rol por defecto al registrarse

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _autenticar() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor, rellena todos los campos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- INICIAR SESIÓN ---
        await _supabase.auth.signInWithPassword(email: email, password: password);

        // Si llegamos aquí, todo fue bien. Navegamos al mapa.
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            //MaterialPageRoute(builder: (context) => const HomeSwipeScreen()),
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false, // Esto borra las pantallas anteriores
          );
        }

      } else {
        // --- REGISTRARSE ---
        final nombre = _nombreController.text.trim();
        if (nombre.isEmpty) {
          _mostrarMensaje('Por favor, introduce tu nombre de usuario', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final AuthResponse res = await _supabase.auth.signUp(
          email: email,
          password: password,
          // Aquí guardamos el nombre directamente en la cuenta del usuario en Supabase
          data: {'display_name': nombre},
        );
        final user = res.user;

        if (user != null) {
          // Intentamos guardar su rol en la tabla de perfiles
          await _supabase.from('perfiles').insert({
            'id': user.id,
            'rol': _rolSeleccionado,
          });

          // Si todo va bien, navegamos al mapa
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              //MaterialPageRoute(builder: (context) => const HomeSwipeScreen()),
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          }
        }
      }
    } on AuthException catch (error) {
      _mostrarMensaje(error.message, isError: true);
    } catch (error) {
      // Si la tabla perfiles falla, caerá aquí
      _mostrarMensaje('Error: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin
                    ? 'Introduce tus datos para acceder al olivar'
                    : 'Regístrate para empezar a gestionar tus parcelas',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Campo Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Nombre (Solo visible si estamos en modo Registro)
              if (!_isLogin) ...[
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre y Apellidos',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Selector de Rol (Solo visible si estamos en modo Registro)
              if (!_isLogin) ...[
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Selecciona tu perfil',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'agricultor', child: Text('Agricultor')),
                    DropdownMenuItem(value: 'tecnico', child: Text('Técnico Agrícola')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _rolSeleccionado = newValue);
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Botón Principal de Acción
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _autenticar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón para cambiar entre Login y Registro
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _emailController.clear();
                      _passwordController.clear();
                      _nombreController.clear();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿No tienes cuenta? Regístrate aquí'
                        : '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}