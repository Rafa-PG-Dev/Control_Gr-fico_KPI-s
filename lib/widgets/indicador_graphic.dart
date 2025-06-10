import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:b25_kpi/models/indicator_model.dart';
import 'package:pdf/widgets.dart' as pw;

class IndicadorGraphic extends StatefulWidget {
  final List<Historico> historico;

  const IndicadorGraphic({super.key, required this.historico});

  @override
  State<IndicadorGraphic> createState() => _IndicadorGraphicState();
}

class _IndicadorGraphicState extends State<IndicadorGraphic> with TickerProviderStateMixin {
  late final AnimationController _lineAnimationController;
  final GlobalKey _chartKey = GlobalKey();
  String selectedPeriodo = 'TODO';

  @override
  void initState() {
    super.initState();
    _lineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    super.dispose();
  }

  List<Historico> get _filteredHistorico {
    final now = DateTime.now();
    switch (selectedPeriodo) {
      case '3M':
        return widget.historico
            .where((h) => h.fecha.isAfter(now.subtract(const Duration(days: 90))))
            .toList();
      case '6M':
        return widget.historico
            .where((h) => h.fecha.isAfter(now.subtract(const Duration(days: 180))))
            .toList();
      case '9M':
        return widget.historico
            .where((h) => h.fecha.isAfter(now.subtract(const Duration(days: 270))))
            .toList();
      case '1A':
        return widget.historico
            .where((h) => h.fecha.isAfter(now.subtract(const Duration(days: 365))))
            .toList();
      case 'TODO':
      default:
        return widget.historico;
    }
  }

  double _calculateAverage(List<Historico> datos) {
    if (datos.isEmpty) return 0;
    return datos.map((e) => e.valor).reduce((a, b) => a + b) / datos.length;
  }

  Future<Uint8List?> _captureChartAsImage() async {
    try {
      RenderRepaintBoundary boundary =
          _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error al capturar gráfico: $e");
      return null;
    }
  }

  // Exportar a PDF
  Future<void> _exportToPDF() async {
    final doc = pw.Document();
    final chartImage = await _captureChartAsImage();
    final data = _filteredHistorico
        .map(
          (e) => [
            '${e.fecha.day}/${e.fecha.month}/${e.fecha.year}',
            e.valor.toStringAsFixed(2),
          ],
        )
        .toList();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Informe de Indicador',
                style: pw.TextStyle(fontSize: 24),
              ),
              pw.SizedBox(height: 20),
              if (chartImage != null)
                pw.Image(pw.MemoryImage(chartImage), height: 200),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(headers: ['Fecha', 'Valor'], data: data),
            ],
          );
        },
      ),
    );

    final pdfBytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final pdfFile = File('${tempDir.path}/indicador.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    final xFile = XFile(pdfFile.path, mimeType: 'application/pdf');
    await Share.shareXFiles([xFile], text: 'Informe de indicador');
  }

  // Exportar a Excel
  Future<void> _exportToExcel() async {
    final workbook = xl.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Histórico';

    // Encabezados
    sheet.getRangeByName('A1').setText('Fecha');
    sheet.getRangeByName('B1').setText('Valor');

    // Datos
    for (int i = 0; i < widget.historico.length; i++) {
      final row = i + 2;
      final fecha = widget.historico[i].fecha;
      final valor = widget.historico[i].valor;

      sheet.getRangeByName('A$row').setText(
        '${fecha.day}/${fecha.month}/${fecha.year}',
      );
      sheet.getRangeByName('B$row').setNumber(valor);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    // Guardar archivo en almacenamiento temporal
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/indicador.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    // Compartir como archivo
    final xFile = XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    await Share.shareXFiles([xFile], text: 'Informe de indicador en Excel');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historico = _filteredHistorico..sort((a, b) => a.fecha.compareTo(b.fecha));

    if (historico.isEmpty) {
      return const Center(child: Text('Sin datos históricos'));
    }

    final promedio = _calculateAverage(historico);

    // Ajustar colores según el tema
    final buttonColor = isDark ? Colors.blueAccent : const Color(0xFF1A237E);
    final textColor = isDark ? Colors.white : const Color(0xFF263238);

    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: ['3M', '6M', '9M', '1A', 'TODO'].map((period) {
            return ChoiceChip(
              label: Text(period, style: TextStyle(color: textColor)),
              selected: selectedPeriodo == period,
              onSelected: (_) {
                setState(() => selectedPeriodo = period);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          key: _chartKey,
          child: AspectRatio(
            aspectRatio: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedBuilder(
                animation: _lineAnimationController,
                builder: (context, child) {
                  double progress = _lineAnimationController.value;
                  final total = historico.length;
                  final lastIndex = (total * progress).clamp(0, total - 1).floor();

                  final List<FlSpot> spots = [];
                  for (int i = 0; i <= lastIndex; i++) {
                    spots.add(FlSpot(i.toDouble(), historico[i].valor));
                  }

                  if (lastIndex < total - 1) {
                    final current = historico[lastIndex];
                    final next = historico[lastIndex + 1];
                    final localProgress = (progress * total) - lastIndex;
                    final interpolatedValue =
                        ui.lerpDouble(current.valor, next.valor, localProgress)!;
                    spots.add(FlSpot(lastIndex + localProgress, interpolatedValue));
                  }

                  return LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final fecha = historico[spot.x.toInt()].fecha;
                              return LineTooltipItem(
                                '${fecha.day}/${fecha.month}/${fecha.year}\n${spot.y.toStringAsFixed(2)}',
                                TextStyle(
                                  color: isDark ? Colors.white : Color(0xFF263238),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: ((historico.length / 5).floorToDouble())
                                .clamp(1, double.infinity),
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < historico.length) {
                                final date = historico[index].fecha;
                                return Text(
                                  '${date.month}/${date.year % 100}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white : Color(0xFF263238),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white : Color(0xFF263238),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: isDark ? Colors.white : Colors.grey),
                      ),
                      minX: 0,
                      maxX: (widget.historico.length - 1).toDouble(),
                      minY: widget.historico.map((e) => e.valor).reduce((a, b) => a < b ? a : b) - 1,
                      maxY: widget.historico.map((e) => e.valor).reduce((a, b) => a > b ? a : b) + 1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
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
                          isCurved: false,
                          spots: [
                            FlSpot(0, promedio),
                            FlSpot((historico.length - 1).toDouble(), promedio),
                          ],
                          color: Colors.orange,
                          dashArray: [5, 5],
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            _lineAnimationController.forward(from: 0);
          },
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text("Reproducir Animación", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _exportToPDF,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text("Exportar a PDF", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _exportToExcel,
          icon: const Icon(Icons.grid_on, color: Colors.white),
          label: const Text(
            "Exportar a Excel",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
          ),
        ),
      ],
    );
  }
}
