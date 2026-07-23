import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';

class CargaPedidoCard extends StatelessWidget {
  const CargaPedidoCard({
    required this.pedido,
    required this.onVerDetalle,
    required this.onCargar,
    super.key,
  });

  final PedidoPreparacion pedido;
  final VoidCallback onVerDetalle;
  final VoidCallback? onCargar;

  @override
  Widget build(BuildContext context) => Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pedido.codigo,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _CargaBadge(cargado: pedido.cargado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pedido.cliente,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                pedido.direccion.isEmpty
                    ? 'Dirección no especificada'
                    : pedido.direccion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    Icons.inventory_2,
                    '${pedido.presentacionesSolicitadas} presentaciones',
                  ),
                  _pill(
                    Icons.check_circle,
                    '${pedido.completos} productos completos',
                  ),
                  _pill(
                    Icons.shopping_bag,
                    pedido.paquetes == 0
                        ? 'Paquetes sin registrar'
                        : '${pedido.paquetes} paquetes',
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
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('Ver pedido'),
            ),
            if (onCargar != null)
              ElevatedButton.icon(
                onPressed: onCargar,
                icon: const Icon(Icons.local_shipping, size: 18),
                label: const Text('Marcar cargado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC500),
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF757575)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _CargaBadge extends StatelessWidget {
  const _CargaBadge({required this.cargado});

  final bool cargado;

  @override
  Widget build(BuildContext context) {
    final color = cargado ? Colors.green : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        cargado ? 'Cargado' : 'Listo para cargar',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
