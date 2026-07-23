import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaResumenIndicadores extends StatelessWidget {
  const HojaResumenIndicadores({
    required this.hoja,
    required this.onVerPedidos,
    required this.onVerProductos,
    required this.onVerPreparacion,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerPedidos;
  final VoidCallback onVerProductos;
  final VoidCallback onVerPreparacion;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Pedidos',
        '${hoja.totalPedidos}',
        Icons.receipt_long,
        Colors.blue,
        onVerPedidos,
      ),
      (
        'Clientes',
        '${hoja.totalClientes}',
        Icons.people,
        Colors.teal,
        onVerPedidos,
      ),
      (
        'Productos',
        '${hoja.totalProductosDiferentes}',
        Icons.inventory,
        Colors.orange,
        onVerProductos,
      ),
      (
        'Sin precio',
        '${hoja.pedidosPendientesPrecio}',
        Icons.warning_amber,
        Colors.deepOrange,
        onVerPedidos,
      ),
      (
        'Preparados',
        '${hoja.pedidosPreparados}',
        Icons.check_circle,
        Colors.green,
        onVerPreparacion,
      ),
      (
        'Pendientes',
        '${hoja.pedidosPendientes}',
        Icons.pending,
        Colors.red,
        onVerPreparacion,
      ),
    ];
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: item.$5,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$3, size: 20, color: item.$4),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      item.$1,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
