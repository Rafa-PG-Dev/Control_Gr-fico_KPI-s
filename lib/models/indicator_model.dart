import 'package:cloud_firestore/cloud_firestore.dart';

class Indicator {
  final String id;
  final String nombre;
  final String descripcion;
  final String area;
  final String unidad;
  final String frecuencia;
  double? valorActual;
  DateTime? fechaUltimaActualizacion;
  final List<Historico> historico;

  Indicator({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.area,
    required this.unidad,
    required this.frecuencia,
    this.valorActual,
    this.fechaUltimaActualizacion,
    required this.historico,
  });

  factory Indicator.fromMap(String id, Map<String, dynamic> data) {
    return Indicator(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      area: data['area'] ?? '',
      unidad: data['unidad'] ?? 'otro',
      frecuencia: data['frecuencia'] ?? 'mensual',
      valorActual: null, // se calcula luego desde el histórico
      fechaUltimaActualizacion: null,
      historico: [], // también se carga luego
    );
  }

  /// Calcula y actualiza el valor actual y la fecha desde el histórico.
  void actualizarValoresDesdeHistorico() {
    if (historico.isEmpty) return;

    historico.sort(
      (a, b) => b.fecha.compareTo(a.fecha),
    ); // más reciente primero
    valorActual = historico.first.valor;
    fechaUltimaActualizacion = historico.first.fecha;
  }

  /// Estado calculado según valorActual
  EstadoIndicador get estado {
    if (valorActual == null) return EstadoIndicador.enMejora; // por defecto
    if (valorActual! < 50) return EstadoIndicador.critico;
    if (valorActual! < 75) return EstadoIndicador.enMejora;
    return EstadoIndicador.correcto;
  }
}

/// Enum para el estado del indicador
enum EstadoIndicador { critico, enMejora, correcto }

/// Modelo del histórico
class Historico {
  final DateTime fecha;
  final double valor;

  Historico({required this.fecha, required this.valor});

  factory Historico.fromMap(Map<String, dynamic> data) {
    return Historico(
      fecha:
          data['fecha'] is Timestamp
              ? (data['fecha'] as Timestamp).toDate()
              : DateTime.parse(data['fecha'] as String),
      valor: (data['valor'] as num).toDouble(),
    );
  }
}
