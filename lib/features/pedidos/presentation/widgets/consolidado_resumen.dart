import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_consolidado.dart';

class ConsolidadoResumen extends StatelessWidget {
  const ConsolidadoResumen({required this.productos, super.key});

  final List<ProductoConsolidado> productos;

  @override
  Widget build(BuildContext context) {
    final distribuciones = productos.expand((item) => item.distribucion);
    final pedidos = distribuciones.map((item) => item.pedidoId).toSet().length;
    final clientes = distribuciones
        .map((item) => item.clienteId.isEmpty ? item.cliente : item.clienteId)
        .toSet()
        .length;
    final totalUnidades = productos.fold<int>(
      0,
      (total, item) => total + item.totalRequerido,
    );
    final pendientes = productos
        .where((item) => item.totalPreparado == 0 && item.pendiente > 0)
        .length;
    final parciales = productos.where((item) => item.parcial).length;
    final completos = productos.where((item) => item.completo).length;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ResumenChip(
            icon: Icons.inventory_2_outlined,
            label: 'Productos',
            value: productos.length,
          ),
          _ResumenChip(
            icon: Icons.straighten,
            label: 'Equiv. unidades',
            value: totalUnidades,
          ),
          _ResumenChip(
            icon: Icons.pending_outlined,
            label: 'Pendientes',
            value: pendientes,
            color: const Color(0xFFF57C00),
          ),
          _ResumenChip(
            icon: Icons.hourglass_bottom,
            label: 'Parciales',
            value: parciales,
            color: const Color(0xFF1976D2),
          ),
          _ResumenChip(
            icon: Icons.check_circle_outline,
            label: 'Completos',
            value: completos,
            color: const Color(0xFF2E7D32),
          ),
          _ResumenChip(
            icon: Icons.receipt_long_outlined,
            label: 'Pedidos',
            value: pedidos,
          ),
          _ResumenChip(
            icon: Icons.people_outline,
            label: 'Clientes',
            value: clientes,
          ),
        ],
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  const _ResumenChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color = const Color(0xFF616161),
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
