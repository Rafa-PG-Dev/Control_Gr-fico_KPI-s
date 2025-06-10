import 'package:flutter/material.dart';
import '../models/indicator_model.dart';
import '../services/firestore_service.dart';
import '../widgets/indicador_card.dart';
import '../widgets/editable_widget.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Indicator> _indicadores = [];
  List<Indicator> _filtrados = [];

  String? _areaSeleccionada;
  int? _anioSeleccionado;
  EstadoIndicador? _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarIndicadores();
  }

  Future<void> _cargarIndicadores() async {
    final indicadores = await _firestoreService.getIndicatorsOnce(
      'centro_madrid',
    );
    setState(() {
      _indicadores = indicadores;
      _filtrados = indicadores;
    });
  }

  void _filtrar() {
    setState(() {
      _filtrados =
          _indicadores.where((ind) {
            final cumpleArea =
                _areaSeleccionada == null || ind.area == _areaSeleccionada;
            final cumpleAnio =
                _anioSeleccionado == null ||
                (ind.fechaUltimaActualizacion?.year == _anioSeleccionado);
            final cumpleEstado =
                _estadoSeleccionado == null ||
                ind.estado == _estadoSeleccionado;
            return cumpleArea && cumpleAnio && cumpleEstado;
          }).toList();
    });
  }

  void _reiniciarFiltros() {
    setState(() {
      _areaSeleccionada = null;
      _anioSeleccionado = null;
      _estadoSeleccionado = null;
      _filtrados = _indicadores;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Indicadores")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDropdownFilter<String>(
                          icon: Icons.category,
                          label: 'Área',
                          value: _areaSeleccionada,
                          items: ['alumnado', 'profesorado', 'resultados'],
                          onChanged: (value) {
                            _areaSeleccionada = value;
                            _filtrar();
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter<int>(
                          icon: Icons.calendar_today,
                          label: 'Año',
                          value: _anioSeleccionado,
                          items: List.generate(
                            5,
                            (i) => DateTime.now().year - i,
                          ),
                          onChanged: (value) {
                            _anioSeleccionado = value;
                            _filtrar();
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter<EstadoIndicador>(
                          icon: Icons.traffic,
                          label: 'Estado',
                          value: _estadoSeleccionado,
                          items: EstadoIndicador.values,
                          itemText: _mapEstadoToTexto,
                          onChanged: (value) {
                            _estadoSeleccionado = value;
                            _filtrar();
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _reiniciarFiltros,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reiniciar Filtros'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _filtrados.isEmpty
                    ? const Center(
                      child: Text('No se encontraron indicadores.'),
                    )
                    : ListView.builder(
                      itemCount: _filtrados.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            IndicadorCard(indicador: _filtrados[index]),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () async {
                                  final actualizado = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => EditableWidget(
                                          indicador: _filtrados[index],
                                        ),
                                  );
                                  if (actualizado == true) {
                                    await _cargarIndicadores();
                                    _filtrar();
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String _mapEstadoToTexto(EstadoIndicador estado) {
    switch (estado) {
      case EstadoIndicador.critico:
        return 'Crítico';
      case EstadoIndicador.enMejora:
        return 'En mejora';
      case EstadoIndicador.correcto:
        return 'Correcto';
    }
  }

  Widget _buildDropdownFilter<T>({
    required IconData icon,
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String Function(T)? itemText,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<T>(
            value: items.contains(value) ? value : null, // ✅ Corrección clave
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Selecciona $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items:
                items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemText != null ? itemText(item) : item.toString(),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
