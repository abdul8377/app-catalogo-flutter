import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';
import 'hoja_estado_badge.dart';
import 'hoja_sync_badge.dart';

class HojaActivaHeroCard extends StatelessWidget {
  const HojaActivaHeroCard({
    required this.hoja,
    required this.onVerDetalle,
    required this.onVerPedidos,
    required this.onCompletar,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerDetalle;
  final VoidCallback onVerPedidos;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFC500);
    const darkColor = Color(0xFF1F1F1F);
    final duracion = DateTime.now().difference(hoja.fechaApertura).inDays;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: darkColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOJA ACTIVA',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      hoja.codigo,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: darkColor,
                      ),
                    ),
                  ],
                ),
              ),
              HojaEstadoBadge(estado: hoja.estado),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.calendar_today,
                  'Iniciada',
                  DateFormat('dd/MM/yyyy • HH:mm').format(hoja.fechaApertura),
                ),
                const SizedBox(height: 8),
                _infoRow(Icons.person_outline, 'Vendedor', hoja.vendedor),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.timer_outlined,
                  'Duración',
                  '$duracion ${duracion == 1 ? 'día' : 'días'}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_outlined,
                      size: 16,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 8),
                    const Text('Estado: '),
                    HojaSyncBadge(
                      sincronizado: hoja.sincronizado,
                      compacto: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Pedidos', '${hoja.totalPedidos}', Colors.blue),
              _metric('Clientes', '${hoja.totalClientes}', Colors.teal),
              _metric(
                'Productos',
                '${hoja.totalProductosDiferentes}',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  (hoja.pedidosPendientesPrecio > 0
                          ? Colors.orange
                          : Colors.green)
                      .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final label = Text(
                      hoja.pedidosPendientesPrecio > 0
                          ? 'Total conocido — incluye IGV:'
                          : 'Total — incluye IGV:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757575),
                      ),
                    );
                    final amount = Text(
                      'S/ ${hoja.subtotalConocido.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: darkColor,
                      ),
                    );
                    if (constraints.maxWidth < 440) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [label, const SizedBox(height: 4), amount],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: label),
                        const SizedBox(width: 12),
                        amount,
                      ],
                    );
                  },
                ),
                if (hoja.pedidosPendientesPrecio > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${hoja.pedidosPendientesPrecio} pedidos pendientes de valorización',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 640;
              final buttons = [
                ElevatedButton.icon(
                  onPressed: onVerDetalle,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver detalle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onVerPedidos,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Ver pedidos'),
                  style: _outlineStyle(),
                ),
                OutlinedButton.icon(
                  onPressed: onCompletar,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Completar'),
                  style: _outlineStyle(),
                ),
              ];
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < buttons.length; index++) ...[
                      buttons[index],
                      if (index < buttons.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    Expanded(child: buttons[index]),
                    if (index < buttons.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1F1F1F),
    side: const BorderSide(color: Color(0xFFE0E0E0)),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF757575)),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: const Color(0xFF757575),
        ),
      ),
      Expanded(
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
      ),
    ],
  );

  Widget _metric(String label, String value, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF757575),
          ),
        ),
      ],
    ),
  );
}
