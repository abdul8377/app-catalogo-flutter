import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreparacionGrupoHeader extends StatelessWidget {
  const PreparacionGrupoHeader({
    required this.titulo,
    required this.cantidad,
    this.color,
    super.key,
  });

  final String titulo;
  final int cantidad;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFFF5F5F5)).withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          if (color != null) ...[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$cantidad pedidos',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}
