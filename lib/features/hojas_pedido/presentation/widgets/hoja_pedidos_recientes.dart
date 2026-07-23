import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaPedidosRecientes extends StatelessWidget {
  const HojaPedidosRecientes({
    required this.hoja,
    required this.onVerTodos,
    required this.onVerPedido,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerTodos;
  final ValueChanged<PedidoEnHoja> onVerPedido;

  @override
  Widget build(BuildContext context) => _section(
    title: 'Pedidos recientes',
    action: 'Ver todos',
    onAction: onVerTodos,
    child: hoja.ultimosPedidos.isEmpty
        ? Text(
            'La hoja está abierta, pero todavía no contiene pedidos.',
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          )
        : Column(
            children: hoja.ultimosPedidos
                .map(
                  (pedido) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => onVerPedido(pedido),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pedido.codigo,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    pedido.cliente,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${pedido.cantidadProductos} productos • ${pedido.tienePrecio ? 'S/ ${pedido.total!.toStringAsFixed(2)}' : 'Pendiente de valorización'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFFBDBDBD),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _section({
    required String title,
    required String action,
    required VoidCallback onAction,
    required Widget child,
  }) => Container(
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
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}
