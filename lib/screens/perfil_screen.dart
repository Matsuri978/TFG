import 'package:flutter/material.dart';

import 'package:tfg/services/services.dart';
import 'package:tfg/screens/screens.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _user = AuthService.instance.currentUser;

  String? _rol;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  Future<void> _cargarDatosPerfil() async {
    if (_user != null) {
      final rolObtenido = await AuthService.instance.obtenerRol(_user!.id);
      if (mounted) {
        setState(() {
          _rol = rolObtenido;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _rol = 'invitado';
        _isLoading = false;
      });
    }
  }

  Future<void> _cerrarSesion(bool esInvitado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esInvitado ? 'Salir' : 'Cerrar Sesión'),
        content: Text(esInvitado
            ? '¿Quieres volver a la pantalla de inicio?'
            : '¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!esInvitado) {
        await AuthService.instance.signOut();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esInvitado = _user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, size: 60, color: Colors.green.shade900),
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoCard(
              titulo: 'Nombre',
              valor: esInvitado ? 'Invitado' : (_user!.userMetadata?['display_name'] ?? 'Usuario'),
              icon: Icons.badge_outlined,
            ),
            _buildInfoCard(
              titulo: 'Correo Electrónico',
              valor: esInvitado ? 'N/A' : _user!.email ?? 'Sin email',
              icon: Icons.email_outlined,
            ),
            _buildInfoCard(
              titulo: 'Rol en el sistema',
              valor: _rol != null ? _rol![0].toUpperCase() + _rol!.substring(1) : 'Cargando...',
              icon: Icons.settings_accessibility,
            ),

            const SizedBox(height: 30),

            const Text(
              'Permisos de tu cuenta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),


            ...AuthService.instance.obtenerPermisos(_rol ?? 'invitado').entries.map((entrada) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entrada.value ? Icons.check_circle : Icons.cancel,
                  color: entrada.value ? Colors.green : Colors.red,
                  size: 28,
                ),
                title: Text(
                  entrada.key,
                  style: TextStyle(
                    fontSize: 16,
                    color: entrada.value ? Colors.black87 : Colors.grey,
                    decoration: entrada.value ? TextDecoration.none : TextDecoration.lineThrough,
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _cerrarSesion(esInvitado),
                icon: Icon(esInvitado ? Icons.login : Icons.logout),
                label: Text(
                  esInvitado ? 'Salir' : 'Cerrar Sesión',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String titulo, required String valor, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }
}