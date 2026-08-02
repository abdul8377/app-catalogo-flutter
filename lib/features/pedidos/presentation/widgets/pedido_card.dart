import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_resumen.dart';
import 'pedido_estado_badge.dart';
import 'pedido_sync_badge.dart';

class PedidoCard extends StatelessWidget {
  const PedidoCard({
    required this.pedido,
    this.onVerPedido,
    this.onCambiarEstado,
    this.onMenuSelected,
    super.key,
  });

  final PedidoResumen pedido;
  final VoidCallback? onVerPedido;
  final VoidCallback? onCambiarEstado;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final estadoColor = pedidoEstadoColor(pedido.estadoNormalizado);
    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: ColoredBox(color: estadoColor),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Padding(
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
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      PedidoEstadoBadge(pedido: pedido),
                      const SizedBox(width: 6),
                      PedidoSyncBadge(pedido: pedido),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(pedido.fecha),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pedido.clienteNombre,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                  _infoLine('Teléfono: ${pedido.telefono}'),
                  _infoLine(_direccionTexto()),
                  if (pedido.referencia.isNotEmpty)
                    _infoLine(pedido.referencia, italic: true),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${pedido.cantidadProductos} productos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '• ${pedido.cantidadPresentaciones} presentaciones',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pedido.productosTexto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pedido.cotizacionVigente) ...[
                    _amountLine('Subtotal sin IGV', pedido.totalSinIgv),
                    _amountLine('IGV (18 %)', pedido.igv),
                    _amountLine('Total', pedido.totalCotizado, emphasize: true),
                  ] else ...[
                    Text(
                      'Subtotal conocido: S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (pedido.productosSinPrecio > 0)
                      Text(
                        '${pedido.productosSinPrecio} producto(s) pendiente(s) de valorización',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    Text(
                      pedido.productosSinPrecio > 0
                          ? 'Total: Por definir'
                          : 'Total: S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Hoja: ${pedido.hojaCodigo}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ver = ElevatedButton(
                        onPressed: onVerPedido,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC500),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ver pedido'),
                      );
                      final estado = OutlinedButton(
                        onPressed: onCambiarEstado,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              pedido.estadoNormalizado == 'cancelado'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1F1F1F),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          pedido.estadoNormalizado == 'cancelado'
                              ? 'Reactivar pedido'
                              : 'Cambiar estado',
                        ),
                      );
                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ver,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: estado),
                                const SizedBox(width: 6),
                                _menuButton(),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: ver),
                          const SizedBox(width: 8),
                          Expanded(child: estado),
                          const SizedBox(width: 4),
                          _menuButton(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton() => PopupMenuButton<String>(
    padding: EdgeInsets.zero,
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF1F1F1F)),
    ),
    onSelected: onMenuSelected,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'cotizacion',
        child: Text(
          pedido.cotizacionVigente
              ? 'Ver / nueva cotización'
              : 'Generar cotización',
        ),
      ),
      const PopupMenuItem(value: 'cliente', child: Text('Ver cliente')),
      const PopupMenuItem(value: 'hoja', child: Text('Ver hoja de pedido')),
      if (pedido.estadoNormalizado != 'cancelado' &&
          pedido.estadoNormalizado != 'entregado')
        const PopupMenuItem(
          value: 'editar_pedido',
          child: Text('Editar productos del pedido'),
        ),
      if (pedido.estadoNormalizado == 'cancelado')
        const PopupMenuItem(
          value: 'reactivar',
          child: Text('Reactivar pedido'),
        ),
      if (pedido.estadoNormalizado != 'cancelado' &&
          pedido.estadoNormalizado != 'entregado')
        const PopupMenuItem(value: 'cancelar', child: Text('Cancelar pedido')),
      if (!pedido.sincronizado || pedido.syncError != null)
        const PopupMenuItem(
          value: 'sync',
          child: Text('Reintentar sincronización'),
        ),
    ],
  );

  Widget _amountLine(String label, double amount, {bool emphasize = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              'S/ ${amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: emphasize ? 15 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  Widget _infoLine(String text, {bool italic = false}) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: const Color(0xFF616161),
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    ),
  );

  String _direccionTexto() {
    if (pedido.direccion.trim().isEmpty) return 'Dirección no especificada';
    return pedido.direccion;
  }

  String _formatDateTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $hour12:$minute $period';
  }
}
