import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaProgresoOperativo extends StatelessWidget {
  const HojaProgresoOperativo({required this.hoja, super.key});

  final HojaPedido hoja;

  @override
  Widget build(BuildContext context) {
    final valorizacion = hoja.totalPedidos == 0
        ? 0.0
        : (hoja.totalPedidos - hoja.pedidosPendientesPrecio) /
              hoja.totalPedidos;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso general',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _bar('Valorización', valorizacion, Colors.blue),
          const SizedBox(height: 12),
          _bar('Preparación', hoja.progresoPreparacion, Colors.orange),
          const SizedBox(height: 12),
          _bar('Carga', hoja.progresoCarga, Colors.teal),
          const SizedBox(height: 12),
          Text(
            '${hoja.pedidosPreparados} de ${hoja.totalPedidos} pedidos preparados completamente',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, Color color) {
    final progress = value.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}
