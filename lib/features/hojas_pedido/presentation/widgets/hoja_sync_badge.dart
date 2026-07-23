import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HojaSyncBadge extends StatelessWidget {
  const HojaSyncBadge({
    required this.sincronizado,
    this.oscuro = false,
    this.compacto = false,
    super.key,
  });

  final bool sincronizado;
  final bool oscuro;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final color = sincronizado
        ? const Color(0xFF43A047)
        : const Color(0xFFF57C00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: oscuro ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sincronizado ? Icons.cloud_done : Icons.cloud_off_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            sincronizado
                ? (compacto ? 'Listo' : 'Sincronizado')
                : (compacto ? 'Local' : 'Guardada localmente'),
            style: GoogleFonts.inter(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
