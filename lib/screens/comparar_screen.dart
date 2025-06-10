import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/indicator_model.dart';
import 'dart:ui' as ui;

class CompararScreen extends StatefulWidget {
  const CompararScreen({super.key});

  @override
  State<CompararScreen> createState() => _CompararScreenState();
}

class _CompararScreenState extends State<CompararScreen>
    with TickerProviderStateMixin {
  List<Indicator> indicadores = [];
  Indicator? indicador1;
  Indicator? indicador2;

  List<Historico> historico1 = [];
  List<Historico> historico2 = [];

  late final AnimationController _animationController;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _cargarIndicadores();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarIndicadores() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('centros')
            .doc('centro_madrid')
            .collection('indicadores')
            .get();

    final loaded =
        snapshot.docs
            .map((doc) => Indicator.fromMap(doc.id, doc.data()))
            .toList();

    setState(() {
      indicadores = loaded;
      isLoading = false;
    });
  }

  Future<List<Historico>> _cargarHistorico(String id) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('centros')
            .doc('centro_madrid')
            .collection('indicadores')
            .doc(id)
            .collection('historico')
            .orderBy('fecha')
            .get();

    return snapshot.docs.map((doc) => Historico.fromMap(doc.data())).toList();
  }

  Widget _buildDropdown(
    String label,
    Indicator? selected,
    List<Indicator> opciones,
    void Function(Indicator?) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<Indicator>(
      value: selected,
      items: opciones
          .map((i) => DropdownMenuItem(value: i, child: Text(i.nombre)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF263238),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: isDark ? const Color(0xFF424242) : Colors.white,
      ),
    );
  }

  List<FlSpot> buildSpots(List<Historico> data, double progress) {
    final List<FlSpot> spots = [];
    int total = data.length;
    if (total == 0) return spots;

    int lastIndex = (total * progress).clamp(0, total - 1).floor();

    for (int i = 0; i <= lastIndex; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].valor));
    }

    if (lastIndex < total - 1) {
      final current = data[lastIndex];
      final next = data[lastIndex + 1];
      double localProgress = (progress * total) - lastIndex;
      double interpolatedValue =
          ui.lerpDouble(current.valor, next.valor, localProgress)!;
      spots.add(FlSpot(lastIndex + localProgress, interpolatedValue));
    }

    return spots;
  }

  Widget _buildChartAnimated() {
    if (historico1.isEmpty && historico2.isEmpty) {
      return Center(
        child: Text(
          "Selecciona dos indicadores y pulsa Comparar.",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF263238),
          ),
        ),
      );
    }

    final allValues = [
      ...historico1.map((h) => h.valor),
      ...historico2.map((h) => h.valor),
    ];
    double minY = allValues.reduce((a, b) => a < b ? a : b) - 1;
    double maxY = allValues.reduce((a, b) => a > b ? a : b) + 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          double progress = _animationController.value;

          final spots1 = buildSpots(historico1, progress);
          final spots2 = buildSpots(historico2, progress);

          return LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (val, meta) {
                      int index = val.toInt();
                      if (index >= 0 && index < historico1.length) {
                        final date = historico1[index].fecha;
                        return Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF263238),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget:
                        (val, meta) => Text(
                          val.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF263238),
                          ),
                        ),
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots1,
                  isCurved: true,
                  color: const Color(0xFF1A237E),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: spots2,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarGrafico() async {
    if (indicador1 == null || indicador2 == null) return;

    final h1 = await _cargarHistorico(indicador1!.id);
    final h2 = await _cargarHistorico(indicador2!.id);

    setState(() {
      historico1 = h1;
      historico2 = h2;
    });

    _animationController.forward(from: 0);
  }

  Widget _buildLegend() {
    if (indicador1 == null ||
        indicador2 == null ||
        historico1.isEmpty ||
        historico2.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF424242)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white30
                : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFF1A237E), radius: 6),
              const SizedBox(width: 8),
              Expanded(child: Text(indicador1!.nombre)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.red, radius: 6),
              const SizedBox(width: 8),
              Expanded(child: Text(indicador2!.nombre)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar para que al elegir una opción no aparezca en el otro menú
    final opciones1 = indicadores.where((i) => i != indicador2).toList();
    final opciones2 = indicadores.where((i) => i != indicador1).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: const Color(0xFF263238),
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              padding: const EdgeInsets.only(left: 20, top: 35),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    color: Colors.white, // flecha de color blanco
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Comparar Indicadores',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDropdown('Indicador 1', indicador1, opciones1, (val) {
              setState(() {
                indicador1 = val;
                if (indicador2 == indicador1) {
                  indicador2 = null;
                  historico2 = [];
                }
              });
            }),
            const SizedBox(height: 16),
            _buildDropdown('Indicador 2', indicador2, opciones2, (val) {
              setState(() {
                indicador2 = val;
                if (indicador1 == indicador2) {
                  indicador1 = null;
                  historico1 = [];
                }
              });
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _mostrarGrafico,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 50),
              ),
              child: const Text('Comparar'),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: _buildChartAnimated()),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
}
