import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';
import 'hoja_estado_badge.dart';
import 'hoja_sync_badge.dart';

class HojaPedidoCard extends StatelessWidget {
  const HojaPedidoCard({
    required this.hoja,
    required this.onVerHoja,
    required this.onVerPedidos,
    required this.onVerConsolidado,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerHoja;
  final VoidCallback onVerPedidos;
  final VoidCallback onVerConsolidado;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8E8E8)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
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
                hoja.codigo,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            HojaEstadoBadge(estado: hoja.estado),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${DateFormat('dd/MM/yyyy').format(hoja.fechaApertura)} - ${hoja.fechaCierre == null ? '—' : DateFormat('dd/MM/yyyy').format(hoja.fechaCierre!)}',
          style: GoogleFonts.inter(
            color: const Color(0xFF757575),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vendedor: ${hoja.vendedor}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        if (hoja.referencia.isNotEmpty) Text('Referencia: ${hoja.referencia}'),
        const SizedBox(height: 14),
        Text(
          '${hoja.totalPedidos} pedidos • ${hoja.totalClientes} clientes • ${hoja.totalProductosDiferentes} productos',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'Total conocido — incluye IGV: S/ ${hoja.subtotalConocido.toStringAsFixed(2)}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        if (hoja.pedidosPendientesPrecio > 0)
          Text(
            '${hoja.pedidosPendientesPrecio} pedidos pendientes de valorización',
            style: GoogleFonts.inter(
              color: Colors.orange.shade800,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 14),
        _progress('Preparación', hoja.progresoPreparacion, Colors.orange),
        const SizedBox(height: 8),
        _progress('Carga', hoja.progresoCarga, Colors.teal),
        const SizedBox(height: 8),
        Text(
          'Pedidos entregados: ${hoja.pedidosEntregados} de ${hoja.totalPedidos}',
        ),
        const SizedBox(height: 10),
        HojaSyncBadge(sincronizado: hoja.sincronizado),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onVerHoja,
              icon: const Icon(Icons.visibility, size: 17),
              label: const Text('Ver hoja'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC500),
                foregroundColor: Colors.black,
              ),
            ),
            OutlinedButton(
              onPressed: onVerPedidos,
              child: const Text('Ver pedidos'),
            ),
            OutlinedButton(
              onPressed: onVerConsolidado,
              child: const Text('Ver consolidado'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _progress(String label, double value, Color color) => Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('${(value.clamp(0, 1) * 100).round()}%'),
    ],
  );
}
