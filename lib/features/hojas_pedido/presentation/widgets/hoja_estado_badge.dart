import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HojaEstadoBadge extends StatelessWidget {
  const HojaEstadoBadge({required this.estado, super.key});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final abierta = estado.toLowerCase() == 'abierta';
    final color = abierta ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        abierta ? 'Abierta' : 'Completada',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}
