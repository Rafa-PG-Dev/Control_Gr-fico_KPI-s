import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/indicator_model.dart';
import '../widgets/indicador_graphic.dart';

class IndicatorDetailScreen extends StatefulWidget {
  final Indicator indicador;

  const IndicatorDetailScreen({super.key, required this.indicador});

  @override
  State<IndicatorDetailScreen> createState() => _IndicatorDetailScreenState();
}

class _IndicatorDetailScreenState extends State<IndicatorDetailScreen> {
  List<Historico> historico = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistorico();
  }

  Future<void> fetchHistorico() async {
    setState(() {
      isLoading = true;
    });

    final snapshot =
        await FirebaseFirestore.instance
            .collection('centros')
            .doc('centro_madrid')
            .collection('indicadores')
            .doc(widget.indicador.id)
            .collection('historico')
            .orderBy('fecha')
            .get();

    setState(() {
      historico =
          snapshot.docs.map((doc) => Historico.fromMap(doc.data())).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.indicador.nombre)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.indicador.descripcion,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    IndicadorGraphic(historico: historico),
                    const SizedBox(height: 24),
                    Text('Área: ${widget.indicador.area}'),
                    Text('Frecuencia: ${widget.indicador.frecuencia}'),
                    Text('Unidad: ${widget.indicador.unidad}'),
                    Text(
                      'Última actualización: ${widget.indicador.fechaUltimaActualizacion?.day}/${widget.indicador.fechaUltimaActualizacion?.month}/${widget.indicador.fechaUltimaActualizacion?.year}',
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchHistorico,
        tooltip: 'Actualizar gráfico',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
