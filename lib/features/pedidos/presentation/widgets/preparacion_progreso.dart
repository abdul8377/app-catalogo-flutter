import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';

class PreparacionProgreso extends StatelessWidget {
  const PreparacionProgreso({required this.pedidos, super.key});

  final List<PedidoPreparacion> pedidos;

  @override
  Widget build(BuildContext context) {
    final pendientes = pedidos
        .where((pedido) => pedido.estadoPreparacion == 'pendiente')
        .length;
    final enPreparacion = pedidos
        .where((pedido) => pedido.estadoPreparacion == 'en_preparacion')
        .length;
    final listosCarga = pedidos
        .where((pedido) => pedido.listoParaCargar)
        .length;
    final cargados = pedidos.where((pedido) => pedido.cargado).length;
    final unidadesPendientes = pedidos.fold<int>(
      0,
      (sum, pedido) => sum + pedido.unidadesPendientes,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(
              Icons.pending_actions,
              'Pendientes',
              pendientes,
              Colors.orange,
            ),
            _chip(
              Icons.inventory,
              'En preparación',
              enPreparacion,
              Colors.blue,
            ),
            _chip(
              Icons.local_shipping,
              'Listos carga',
              listosCarga,
              Colors.teal,
            ),
            _chip(Icons.check_circle, 'Cargados', cargados, Colors.green),
            _chip(
              Icons.straighten,
              'Und. pendientes',
              unidadesPendientes,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    IconData icon,
    String label,
    int count,
    Color color,
  ) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    ),
  );
}
