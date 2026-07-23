import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';

class PreparacionPedidoCard extends StatelessWidget {
  const PreparacionPedidoCard({
    required this.pedido,
    required this.onVerDetalle,
    this.onCargar,
    super.key,
  });

  final PedidoPreparacion pedido;
  final VoidCallback onVerDetalle;
  final VoidCallback? onCargar;

  @override
  Widget build(BuildContext context) {
    final progress = pedido.progreso.clamp(0, 1).toDouble();
    const primaryColor = Color(0xFFFFC500);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pedido.codigo,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (pedido.paquetes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pedido.paquetes} paq.',
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                Text(
                  pedido.cliente,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  pedido.direccion.isEmpty
                      ? 'Dirección no especificada'
                      : pedido.direccion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}% • ${pedido.completos}/${pedido.totalProductos} prod.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                    if (pedido.empresa.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          pedido.empresa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF616161),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onVerDetalle,
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('Ver productos'),
              ),
              if (onCargar != null)
                ElevatedButton.icon(
                  onPressed: onCargar,
                  icon: const Icon(Icons.local_shipping, size: 16),
                  label: const Text('Cargar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
