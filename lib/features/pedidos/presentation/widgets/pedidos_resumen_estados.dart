import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/pedidos_listado/pedidos_listado_state.dart';
import 'pedido_estado_badge.dart';

class PedidosResumenEstados extends StatelessWidget {
  const PedidosResumenEstados({
    required this.state,
    required this.onTap,
    super.key,
  });

  final PedidosListadoState state;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ResumenEstadoItem(
        label: 'Pendientes',
        filtro: 'Pendiente',
        estadoKey: 'pendiente',
        count: state.countEstado('pendiente'),
      ),
      _ResumenEstadoItem(
        label: 'En proceso',
        filtro: 'En proceso',
        estadoKey: 'en_proceso',
        count: state.countEstado('en_proceso'),
      ),
      _ResumenEstadoItem(
        label: 'Listos para entregar',
        filtro: 'Listo para entregar',
        estadoKey: 'listo',
        count: state.countEstado('listo'),
      ),
      _ResumenEstadoItem(
        label: 'Entregados',
        filtro: 'Entregado',
        estadoKey: 'entregado',
        count: state.countEstado('entregado'),
      ),
      _ResumenEstadoItem(
        label: 'Cancelados',
        filtro: 'Cancelado',
        estadoKey: 'cancelado',
        count: state.countEstado('cancelado'),
      ),
      _ResumenEstadoItem(
        label: 'Sin precio',
        filtro: 'Pendiente de valorización',
        estadoKey: 'sin_precio',
        count: state.countPendientesPrecio,
        color: const Color(0xFFFF9800),
      ),
    ];

    return Container(
      color: Colors.white,
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final color = item.color ?? pedidoEstadoColor(item.estadoKey);
          final isActive = state.filtrosRapidos.contains(item.filtro);
          return GestureDetector(
            onTap: () => onTap(item.filtro),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: .15)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? color : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: color),
                      const SizedBox(width: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.count}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResumenEstadoItem {
  const _ResumenEstadoItem({
    required this.label,
    required this.filtro,
    required this.estadoKey,
    required this.count,
    this.color,
  });

  final String label;
  final String filtro;
  final String estadoKey;
  final int count;
  final Color? color;
}
