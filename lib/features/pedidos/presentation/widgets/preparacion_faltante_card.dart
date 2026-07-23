import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';

class PreparacionFaltanteCard extends StatelessWidget {
  const PreparacionFaltanteCard({
    required this.pedido,
    required this.producto,
    required this.onTap,
    super.key,
  });

  final PedidoPreparacion pedido;
  final ProductoPreparacion producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${producto.nombre} (${producto.codigo})',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pendiente: ${producto.pendienteTexto}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pedido: ${pedido.codigo} • ${pedido.cliente}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF757575),
              ),
            ),
            Text(
              'Preparado: ${producto.preparadoTexto} de '
              '${producto.solicitadoTexto}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            Text(
              'Equivalencia: ${producto.equivalenciaTexto}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: producto.cantidadSolicitada > 0
                  ? producto.cantidadPreparada / producto.cantidadSolicitada
                  : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
          ],
        ),
      ),
    ),
  );
}
