import 'package:flutter/material.dart';
import '../models/indicator_model.dart';
import '../screens/indicador_detail_screen.dart';

class IndicadorCard extends StatelessWidget {
  final Indicator indicador;
  final VoidCallback? onEdit; // <- nuevo parámetro opcional

  const IndicadorCard({
    super.key,
    required this.indicador,
    this.onEdit, // <- lo agregamos aquí también
  });

  @override
  Widget build(BuildContext context) {
    double valor = (indicador.valorActual ?? 0).clamp(0, 100);
    Color color = _getColorByValor(valor);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : const Color(0xFF263238);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF757575);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: isDark ? Colors.grey : Colors.white),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(60),
        child: InkWell(
          borderRadius: BorderRadius.circular(60),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => IndicatorDetailScreen(indicador: indicador),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: valor / 100,
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        backgroundColor:
                            isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                      ),
                      Text(
                        '${valor.toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        indicador.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _capitalize(indicador.area),
                        style: TextStyle(
                          fontSize: 16,
                          color: subtitleColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit !=
                    null) // Mostrar el lápiz solo si se pasa el callback
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: textColor,
                    tooltip: 'Editar',
                    onPressed: onEdit,
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color:
                      Colors
                          .transparent, // Oculta para que no se duplique con IconButton
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorByValor(double valor) {
    if (valor > 70) {
      return const Color(0xFF43A047);
    } else if (valor >= 31) {
      return Colors.amber;
    } else {
      return const Color(0xFFE53935);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
