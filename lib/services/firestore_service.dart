import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/indicator_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Indicator>> getIndicators(String centroId) {
    return _db
        .collection('centros')
        .doc(centroId)
        .collection('indicadores')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Indicator> indicators = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String id = doc.id;

            Indicator indicator = Indicator.fromMap(id, data);

            final historicoSnapshot =
                await doc.reference
                    .collection('historico')
                    .orderBy('fecha', descending: true)
                    .limit(1)
                    .get();

            if (historicoSnapshot.docs.isNotEmpty) {
              final latestHistorico = historicoSnapshot.docs.first.data();
              indicator.valorActual =
                  (latestHistorico['valor'] as num).toDouble();
              indicator.fechaUltimaActualizacion =
                  (latestHistorico['fecha'] as Timestamp).toDate();
            }

            indicators.add(indicator);
          }

          return indicators;
        });
  }

  Future<List<Indicator>> getIndicatorsOnce(String centroId) async {
    final snapshot =
        await _db
            .collection('centros')
            .doc(centroId)
            .collection('indicadores')
            .get();

    List<Indicator> indicators = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String id = doc.id;

      Indicator indicator = Indicator.fromMap(id, data);

      final historicoSnapshot =
          await doc.reference
              .collection('historico')
              .orderBy('fecha', descending: true)
              .limit(1)
              .get();

      if (historicoSnapshot.docs.isNotEmpty) {
        final latestHistorico = historicoSnapshot.docs.first.data();
        indicator.valorActual = (latestHistorico['valor'] as num).toDouble();
        indicator.fechaUltimaActualizacion =
            (latestHistorico['fecha'] as Timestamp).toDate();
      }

      indicators.add(indicator);
    }

    return indicators;
  }

  /// Método para actualizar el área, estado y año del indicador.
  Future<void> actualizarDatosBasicos({
    required String centroId,
    required String indicadorId,
    required String area,
    required EstadoIndicador estado,
    required int anio,
  }) async {
    try {
      final docRef = _db
          .collection('centros')
          .doc(centroId)
          .collection('indicadores')
          .doc(indicadorId);

      await docRef.update({
        'area': area,
        'estado': estado.name, // .name para guardar como string
        'fecha_ultima_actualizacion': Timestamp.fromDate(DateTime(anio)),
      });
    } catch (e) {
      print('Error al actualizar datos básicos del indicador: $e');
    }
  }

  Future<void> actualizarValor(Indicator indicador) async {
    final docRef = _db
        .collection('centros')
        .doc('centro_madrid')
        .collection('indicadores')
        .doc(indicador.id);

    final historicoSnapshot =
        await docRef
            .collection('historico')
            .orderBy('fecha', descending: true)
            .limit(1)
            .get();

    double nuevoValorActual = 0.0;
    DateTime fechaUltimaHistorico = DateTime.now();

    if (historicoSnapshot.docs.isNotEmpty) {
      final historicoData = historicoSnapshot.docs.first.data();
      nuevoValorActual = (historicoData['valor'] as num).toDouble();
      fechaUltimaHistorico = (historicoData['fecha'] as Timestamp).toDate();
    }

    DateTime fechaLimite = fechaUltimaHistorico;
    if (indicador.frecuencia == 'mensual') {
      fechaLimite = DateTime(
        fechaUltimaHistorico.year,
        fechaUltimaHistorico.month + 1,
        fechaUltimaHistorico.day,
      );
    } else if (indicador.frecuencia == 'anual') {
      fechaLimite = DateTime(
        fechaUltimaHistorico.year + 1,
        fechaUltimaHistorico.month,
        fechaUltimaHistorico.day,
      );
    } else if (indicador.frecuencia == 'trimestral') {
      fechaLimite = DateTime(
        fechaUltimaHistorico.year,
        fechaUltimaHistorico.month + 3,
        fechaUltimaHistorico.day,
      );
    }

    if (DateTime.now().isAfter(fechaLimite)) {
      await docRef.update({
        'valor_actual': nuevoValorActual,
        'fecha_ultima_actualizacion': DateTime.now(),
      });

      await docRef.collection('historico').add({
        'fecha': DateTime.now(),
        'valor': nuevoValorActual,
      });
    }
  }

  Future<AppUser?> getUserByUID(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      print('Error obteniendo usuario: $e');
    }
    return null;
  }
}
