import 'package:flutter/material.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/services/services.dart';

class OliveHistoryScreen extends StatefulWidget {
  final Olive olive;

  const OliveHistoryScreen({super.key, required this.olive});

  @override
  State<OliveHistoryScreen> createState() => _OliveHistoryScreenState();
}

class _OliveHistoryScreenState extends State<OliveHistoryScreen> {
  // Datos
  late Future<List<Map<String, dynamic>>> _treatmentsFuture;
  late Future<List<Map<String, dynamic>>> _observationsFuture;

  // Filtros comunes
  bool _showDateFilters = false;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _treatmentSearchController = TextEditingController();
  final TextEditingController _observationSearchController = TextEditingController();

  final List<int> _months = List.generate(12, (index) => index + 1);
  final Map<int, String> _monthNames = {
    1: 'Ene', 2: 'Feb', 3: 'Mar', 4: 'Abr', 5: 'May', 6: 'Jun',
    7: 'Jul', 8: 'Ago', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dic'
  };

  // Filtros Tratamientos
  String _treatmentSearch = "";

  // Filtros Observaciones
  String _observationSearch = "";
  String? _selectedObsType;
  String? _selectedObsStatus;

  final List<String> _obsTypes = [
    'General',
    'Plaga',
    'Enfermedad',
    'Poda',
    'Riego',
    'Fertilización'
  ];
  final List<String> _obsStatuses = ['Sano', 'Enfermo', 'En Tratamiento'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _treatmentSearchController.dispose();
    _observationSearchController.dispose();
    super.dispose();
  }

  bool get _anyFilterActive {
    return _selectedYear != null ||
        _selectedMonth != null ||
        _selectedDay != null ||
        _treatmentSearch.isNotEmpty ||
        _observationSearch.isNotEmpty ||
        _selectedObsType != null ||
        _selectedObsStatus != null;
  }

  void _loadData() {
    _treatmentsFuture = DatabaseService.instance.getTreatmentsByOlive(widget.olive.id);
    _observationsFuture = DatabaseService.instance.getObservationsByOlive(widget.olive.id);
  }

  void _resetFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _selectedDay = null;
      _yearController.clear();
      _treatmentSearch = "";
      _treatmentSearchController.clear();
      _observationSearch = "";
      _observationSearchController.clear();
      _selectedObsType = null;
      _selectedObsStatus = null;
    });
  }

  String _formatDate(String? dateStr) {
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

  bool _matchesDate(String? dateStr) {
    if (_selectedYear == null && _selectedMonth == null && _selectedDay == null) return true;
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final DateTime date = DateTime.parse(dateStr);
      if (_selectedYear != null && date.year != _selectedYear) return false;
      if (_selectedMonth != null && date.month != _selectedMonth) return false;
      if (_selectedDay != null && date.day != _selectedDay) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  int _getDaysInMonth(int? year, int? month) {
    if (month == null) return 31;
    return DateUtils.getDaysInMonth(year ?? DateTime.now().year, month);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Historial: Olivo ${widget.olive.id}"),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.science), text: "Tratamientos"),
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
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              Icons.restart_alt,
              color: _anyFilterActive ? Colors.black : Colors.grey,
            ),
            tooltip: "Reiniciar búsqueda",
            onPressed: _anyFilterActive ? _resetFilters : null,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              _showDateFilters ? Icons.filter_alt_off : Icons.filter_alt,
              color: _showDateFilters ? Colors.green : Colors.grey,
            ),
            tooltip: "Filtros",
            onPressed: () => setState(() => _showDateFilters = !_showDateFilters),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildSearchBar(
                controller: _treatmentSearchController,
                hintText: "Buscar producto...",
                onChanged: (val) => setState(() => _treatmentSearch = val),
              ),
              if (_showDateFilters) ...[
                const SizedBox(height: 8),
                _buildProgressiveDateFilter(),
              ]
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _treatmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error al cargar tratamientos."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay tratamientos registrados."));
              }

              final treatments = snapshot.data!.where((t) {
                final matchesSearch = t['producto']
                        ?.toString()
                        .toLowerCase()
                        .contains(_treatmentSearch.toLowerCase()) ??
                    true;
                final matchesDate = _matchesDate(t['fecha_tratamiento']);
                return matchesSearch && matchesDate;
              }).toList();

              if (treatments.isEmpty) {
                return const Center(child: Text("No coinciden tratamientos."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadData();
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: treatments.length,
                  itemBuilder: (context, index) {
                    final t = treatments[index];
                    final fecha = _formatDate(t['fecha_tratamiento']);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        leading: const Icon(Icons.science, color: Colors.blue),
                        title: Text(t['producto'] ?? 'Tratamiento',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fecha: $fecha"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow("Producto", t['producto']),
                                _infoRow("Fecha", fecha),
                                _infoRow("Dosis", t['dosis']),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.green.shade50,
          child: Column(
            children: [
              _buildSearchBar(
                controller: _observationSearchController,
                hintText: "Buscar por tipo, estado...",
                onChanged: (val) => setState(() => _observationSearch = val),
              ),
              if (_showDateFilters) ...[
                const SizedBox(height: 8),
                _buildProgressiveDateFilter(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownFilter(
                        "Tipo",
                        _selectedObsType,
                        _obsTypes,
                        (val) => setState(() => _selectedObsType = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownFilter(
                        "Estado",
                        _selectedObsStatus,
                        _obsStatuses,
                        (val) => setState(() => _selectedObsStatus = val),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _observationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error al cargar observaciones."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay observaciones registradas."));
              }

              final observations = snapshot.data!.where((o) {
                final matchesDate = _matchesDate(o['fecha_observacion']);
                final matchesType = _selectedObsType == null ||
                    o['tipo_observacion'] == _selectedObsType;
                final matchesStatus =
                    _selectedObsStatus == null || o['estado'] == _selectedObsStatus;

                final String searchText = _observationSearch.toLowerCase();
                final matchesText = searchText.isEmpty ||
                    (o['tipo_observacion']?.toString().toLowerCase().contains(searchText) ??
                        false) ||
                    (o['estado']?.toString().toLowerCase().contains(searchText) ??
                        false) ||
                    (o['descripcion']?.toString().toLowerCase().contains(searchText) ??
                        false);

                return matchesDate && matchesType && matchesStatus && matchesText;
              }).toList();

              if (observations.isEmpty) {
                return const Center(child: Text("No coinciden observaciones."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadData();
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: observations.length,
                  itemBuilder: (context, index) {
                    final o = observations[index];
                    final fecha = _formatDate(o['fecha_observacion']);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        leading: const Icon(Icons.remove_red_eye, color: Colors.orange),
                        title: Text(o['tipo_observacion'] ?? 'Observación',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fecha: $fecha"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow("Tipo", o['tipo_observacion']),
                                _infoRow("Fecha", fecha),
                                _infoRow("Estado", o['estado']),
                                _infoRow("Descripción", o['descripcion']),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressiveDateFilter() {
    final int maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    final List<int> currentDaysList = List.generate(maxDays, (i) => i + 1);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: "Año (Ej: 2024)",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedYear = int.tryParse(val);
                  if (_selectedYear == null) {
                    _selectedMonth = null;
                    _selectedDay = null;
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildSimpleDropdown<int>(
            "Mes",
            _selectedMonth,
            _months,
            (val) => setState(() {
              _selectedMonth = val;
              if (val == null) {
                _selectedDay = null;
              } else {
                // Ajustar día si se pasa del límite del nuevo mes
                if (_selectedDay != null) {
                  int max = _getDaysInMonth(_selectedYear, val);
                  if (_selectedDay! > max) _selectedDay = max;
                }
              }
            }),
            (val) => _monthNames[val] ?? val.toString(),
            enabled: _selectedYear != null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildSimpleDropdown<int>(
            "Día",
            _selectedDay,
            currentDaysList,
            (val) => setState(() => _selectedDay = val),
            (val) => val.toString(),
            enabled: _selectedMonth != null,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown<T>(
    String hint,
    T? value,
    List<T> items,
    void Function(T?) onChanged,
    String Function(T) itemText, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint, style: const TextStyle(fontSize: 12)),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            onChanged: enabled ? onChanged : null,
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              ...items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemText(item), style: const TextStyle(fontSize: 12)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String? value, List<String> options,
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 14)),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text("Todos ($label)", style: const TextStyle(fontSize: 14)),
            ),
            ...options.map((String opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(opt, style: const TextStyle(fontSize: 14)),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text("${value ?? 'N/A'}")),
        ],
      ),
    );
  }
}
