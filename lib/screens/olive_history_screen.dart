import 'package:flutter/material.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/services/services.dart';

class OliveHistoryScreen extends StatelessWidget {
  final Olive olive;

  const OliveHistoryScreen({super.key, required this.olive});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Historial Olivo ${olive.id}"),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.medication), text: "Tratamientos"),
              Tab(icon: Icon(Icons.visibility), text: "Observaciones"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildTreatmentsTab(),
            _buildObservationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getTreatmentsByOlive(olive.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay tratamientos registrados."));
        }

        final treatments = snapshot.data!;
        return ListView.builder(
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            final t = treatments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: const Icon(Icons.science, color: Colors.blue),
                title: Text(t['producto'] ?? 'Tratamiento sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Fecha: ${t['fecha_tratamiento'] ?? 'N/A'}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: t.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${entry.key}: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Expanded(child: Text("${entry.value}")),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildObservationsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getObservationsByOlive(olive.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay observaciones registradas."));
        }

        final observations = snapshot.data!;
        return ListView.builder(
          itemCount: observations.length,
          itemBuilder: (context, index) {
            final o = observations[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.orange),
                title: Text(o['tipo_observacion'] ?? 'Observación',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Fecha: ${o['fecha_observacion'] ?? 'N/A'}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: o.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${entry.key}: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Expanded(child: Text("${entry.value}")),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
