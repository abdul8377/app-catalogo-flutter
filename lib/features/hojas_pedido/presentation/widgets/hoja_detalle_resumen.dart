import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaDetalleResumen extends StatelessWidget {
  const HojaDetalleResumen({required this.hoja, super.key});

  final HojaPedido hoja;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _card('Información de la hoja', [
          _row('Código', hoja.codigo),
          _row('Estado', hoja.estado),
          _row('Vendedor', hoja.vendedor),
          _row(
            'Fecha de apertura',
            DateFormat('dd/MM/yyyy').format(hoja.fechaApertura),
          ),
          _row('Hora', DateFormat('HH:mm').format(hoja.fechaApertura)),
          _row(
            'Fecha de cierre',
            hoja.fechaCierre == null
                ? '—'
                : DateFormat('dd/MM/yyyy HH:mm').format(hoja.fechaCierre!),
          ),
        ]),
        _card('Resumen de pedidos', [
          _row('Pedidos totales', '${hoja.totalPedidos}'),
          _row('Pendientes', '${hoja.pedidosPendientes}'),
          _row('En proceso', '${hoja.pedidosEnProceso}'),
          _row('Listos para entregar', '${hoja.pedidosListos}'),
          _row('Entregados', '${hoja.pedidosEntregados}'),
          _row('Cancelados', '${hoja.pedidosCancelados}'),
        ]),
        _card('Resumen económico', [
          _row(
            hoja.pedidosPendientesPrecio > 0
                ? 'Total conocido — incluye IGV'
                : 'Total — incluye IGV',
            'S/ ${hoja.subtotalConocido.toStringAsFixed(2)}',
          ),
          _row(
            'Pedidos con precio completo',
            '${hoja.totalPedidos - hoja.pedidosPendientesPrecio}',
          ),
          _row('Pendientes de valorización', '${hoja.pedidosPendientesPrecio}'),
          if (hoja.pedidosPendientesPrecio > 0)
            _row('Total definitivo', 'Pendiente de valorización'),
        ]),
        _card('Resumen operativo', [
          _row('Productos diferentes', '${hoja.totalProductosDiferentes}'),
          _row('Unidades requeridas', '${hoja.totalUnidades}'),
          _row(
            'Preparación general',
            '${(hoja.progresoPreparacion * 100).round()}%',
          ),
          _row('Pedidos preparados', '${hoja.pedidosPreparados}'),
          _row('Pedidos cargados', '${hoja.pedidosCargados}'),
        ]),
      ],
    ),
  );

  Widget _card(String title, List<Widget> rows) => LayoutBuilder(
    builder: (context, constraints) => Container(
      width: constraints.maxWidth >= 820
          ? (constraints.maxWidth - 20) / 2
          : constraints.maxWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
