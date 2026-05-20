import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/screens/screens.dart';
import 'package:tfg/services/services.dart';

class OliveInfoCard extends StatefulWidget {
  final Olive olive;
  final VoidCallback onClose;

  const OliveInfoCard({
    super.key,
    required this.olive,
    required this.onClose,
  });

  @override
  State<OliveInfoCard> createState() => _OliveInfoCardState();
}

class _OliveInfoCardState extends State<OliveInfoCard> {
  bool _isEditing = false;
  String? _currentStatus;
  String? _selectedStatus;
  final List<String> _statusOptions = ['Sano', 'Enfermo', 'En Tratamiento'];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.olive.healthStatus;
    _selectedStatus = _currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (_currentStatus == 'Enfermo') {
      statusColor = Colors.red;
      statusText = "ATENCIÓN REQUERIDA";
    } else if (_currentStatus == 'En Tratamiento') {
      statusColor = Colors.blue;
      statusText = "EN TRATAMIENTO";
    } else {
      statusColor = Colors.green;
      statusText = "ESTADO ÓPTIMO";
    }

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Card(
        elevation: 10,
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: statusColor, width: 2)),
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
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    avatar: SvgPicture.asset(
                      'assets/olive.svg',
                      colorFilter:
                          ColorFilter.mode(statusColor, BlendMode.srcIn),
                    ),
                    label: Text("${widget.olive.id}: $statusText",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                  CloseButton(onPressed: widget.onClose),
                ],
              ),
              const Divider(),

              const SizedBox(height: 4),
              _buildRowInfo("Variedad:", widget.olive.variety ?? "Desconocida"),
              _buildStatusRow(),
              _buildRowInfo("Longitud:", widget.olive.longitude.toString()),
              _buildRowInfo("Latitud:", widget.olive.latitude.toString()),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.history, size: 16, color: Colors.green),
                        SizedBox(width: 5),
                        Text("Gestión de Olivo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildManagementButtons(),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 35,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OliveHistoryScreen(olive: widget.olive),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt,
                            size: 18, color: Colors.white),
                        label: const Text("Ver Historial",
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 15),

              FutureBuilder<String>(
                future: AuthService.instance.currentUser != null
                    ? AuthService.instance
                        .getRole(AuthService.instance.currentUser!.id)
                    : Future.value('guest'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  String role = snapshot.data!;
                  if (role == 'guest') return const SizedBox.shrink();

                  String label = (role == 'tecnico' || role == 'admin')
                      ? "Registrar Observación/Tratamiento"
                      : "Registrar Tratamiento";

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(label),
                      onPressed: () {
                        // Aquí iría la lógica para abrir un formulario de registro
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Estado:",
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          _isEditing
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isDense: true,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                    items: _statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                  ),
                )
              : Text(_currentStatus ?? "Normal",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildManagementButtons() {
    return FutureBuilder<String>(
      future: AuthService.instance.currentUser != null
          ? AuthService.instance.getRole(AuthService.instance.currentUser!.id)
          : Future.value('guest'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        String role = snapshot.data!;
        if (role != 'tecnico' && role != 'admin') return const SizedBox.shrink();

        if (_isEditing) {
          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _selectedStatus = _currentStatus;
                      });
                    },
                    icon: const Icon(Icons.cancel, size: 16, color: Colors.white),
                    label: const Text("Cancelar",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await DatabaseService.instance
                            .updateOliveStatus(widget.olive.id, _selectedStatus!);
                        setState(() {
                          _currentStatus = _selectedStatus;
                          _isEditing = false;
                        });
                        
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text("Estado actualizado correctamente")),
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text("Error al actualizar: $e"),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text("Aceptar",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
            ],
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 35,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
              label: const Text("Modificar estado",
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }
      },
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
