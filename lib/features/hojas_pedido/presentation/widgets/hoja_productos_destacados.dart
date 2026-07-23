import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaProductosDestacados extends StatelessWidget {
  const HojaProductosDestacados({
    required this.hoja,
    required this.onVerConsolidado,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerConsolidado;

  @override
  Widget build(BuildContext context) => Container(
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Productos más solicitados',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: onVerConsolidado,
              child: const Text('Ver consolidado'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hoja.productosDestacados.isEmpty)
          Text(
            'Los productos aparecerán cuando se registre el primer pedido.',
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          )
        else
          ...hoja.productosDestacados.asMap().entries.map((entry) {
            final producto = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? const Color(0xFFFFC500).withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}º',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${producto.cantidadTotal} ${producto.presentacion} • ${producto.pedidosQueLoIncluyen} pedidos',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );
}
