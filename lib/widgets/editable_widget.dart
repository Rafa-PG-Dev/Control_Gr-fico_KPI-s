import 'package:flutter/material.dart';
import '../models/indicator_model.dart';
import '../services/firestore_service.dart';

class EditableWidget extends StatefulWidget {
  final Indicator indicador;
  const EditableWidget({super.key, required this.indicador});

  @override
  State<EditableWidget> createState() => _EditableWidgetState();
}

class _EditableWidgetState extends State<EditableWidget> {
  final FirestoreService firestoreService = FirestoreService();

  late String? _areaSeleccionada;
  late int? _anioSeleccionado;
  late EstadoIndicador? _estadoSeleccionado;

  bool isEditing = true;

  @override
  void initState() {
    super.initState();
    _areaSeleccionada = widget.indicador.area;
    _anioSeleccionado = widget.indicador.fechaUltimaActualizacion?.year;
    _estadoSeleccionado = widget.indicador.estado;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Indicador'),
      content:
          isEditing
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _areaSeleccionada,
                    hint: const Text('Selecciona área'),
                    items:
                        [
                              'alumnado',
                              'profesorado',
                              'resultados',
                              'captación',
                              'satisfacción',
                              'organizativo',
                              'en mejora',
                            ]
                            .map(
                              (area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _areaSeleccionada = value;
                      });
                    },
                  ),
                  DropdownButton<int>(
                    value: _anioSeleccionado,
                    hint: const Text('Selecciona año'),
                    items:
                        List.generate(5, (i) => DateTime.now().year - i)
                            .map(
                              (anio) => DropdownMenuItem(
                                value: anio,
                                child: Text('$anio'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _anioSeleccionado = value;
                      });
                    },
                  ),
                  DropdownButton<EstadoIndicador>(
                    value: _estadoSeleccionado,
                    hint: const Text('Selecciona estado'),
                    items:
                        EstadoIndicador.values.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(_mapEstadoToTexto(estado)),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _estadoSeleccionado = value;
                      });
                    },
                  ),
                ],
              )
              : const SizedBox.shrink(),
      actions:
          isEditing
              ? [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_areaSeleccionada != null &&
                        _estadoSeleccionado != null &&
                        _anioSeleccionado != null) {
                      await firestoreService.actualizarDatosBasicos(
                        centroId: 'centro_madrid',
                        indicadorId: widget.indicador.id,
                        area: _areaSeleccionada!,
                        estado: _estadoSeleccionado!,
                        anio: _anioSeleccionado!,
                      );

                      setState(() {
                        isEditing = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Datos actualizados correctamente'),
                        ),
                      );

                      Navigator.of(
                        context,
                      ).pop(true); // Devuelve true para actualizar la lista
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor completa todos los campos'),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ]
              : [],
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
}
