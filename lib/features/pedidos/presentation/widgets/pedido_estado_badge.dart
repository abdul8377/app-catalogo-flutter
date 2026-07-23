import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_resumen.dart';

class PedidoEstadoBadge extends StatelessWidget {
  const PedidoEstadoBadge({required this.pedido, super.key});

  final PedidoResumen pedido;

  @override
  Widget build(BuildContext context) {
    final color = pedidoEstadoColor(pedido.estadoNormalizado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        pedido.estadoLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color pedidoEstadoColor(String estado) {
  switch (estado) {
    case 'en_proceso':
      return const Color(0xFF2196F3);
    case 'listo':
      return const Color(0xFF00A8B5);
    case 'entregado':
      return const Color(0xFF4CAF50);
    case 'cancelado':
      return const Color(0xFFEF5350);
    default:
      return const Color(0xFFFFC500);
  }
}
