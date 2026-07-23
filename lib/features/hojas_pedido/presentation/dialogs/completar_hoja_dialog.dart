import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class CompletarHojaDialog extends StatefulWidget {
  const CompletarHojaDialog({required this.hoja, super.key});

  final HojaPedido hoja;

  static Future<String?> show(BuildContext context, HojaPedido hoja) =>
      showDialog<String>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => CompletarHojaDialog(hoja: hoja),
      );

  @override
  State<CompletarHojaDialog> createState() => _CompletarHojaDialogState();
}

class _CompletarHojaDialogState extends State<CompletarHojaDialog> {
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hoja = widget.hoja;
    final noPreparados = hoja.totalPedidos - hoja.pedidosPreparados;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completar hoja ${hoja.codigo}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'La hoja dejará de recibir nuevos pedidos. Los pedidos asociados conservarán su estado y podrán continuar en preparación, carga y entrega.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 20),
              _title('RESUMEN'),
              const SizedBox(height: 8),
              _line('Pedidos', '${hoja.totalPedidos}'),
              _line('Clientes', '${hoja.totalClientes}'),
              _line('Productos diferentes', '${hoja.totalProductosDiferentes}'),
              _line(
                'Subtotal conocido',
                'S/ ${hoja.subtotalConocido.toStringAsFixed(2)}',
              ),
              if (hoja.pedidosPendientesPrecio > 0)
                _line(
                  'Pendientes de valorización',
                  '${hoja.pedidosPendientesPrecio}',
                ),
              if (hoja.pedidosPendientes > 0 ||
                  hoja.pedidosPendientesPrecio > 0 ||
                  noPreparados > 0) ...[
                const SizedBox(height: 16),
                _title('ADVERTENCIAS', color: Colors.orange.shade800),
                const SizedBox(height: 8),
                if (hoja.pedidosPendientes > 0)
                  _warning(
                    '${hoja.pedidosPendientes} pedidos continúan pendientes.',
                  ),
                if (hoja.pedidosPendientesPrecio > 0)
                  _warning(
                    '${hoja.pedidosPendientesPrecio} pedidos aún no tienen precio completo.',
                  ),
                if (noPreparados > 0)
                  _warning(
                    '$noPreparados pedidos todavía no están preparados completamente.',
                  ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _observacionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observación de cierre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _observacionController.text.trim(),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC500),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Completar hoja'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text, {Color color = const Color(0xFF757575)}) => Text(
    text,
    style: GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: color,
    ),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _warning(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        const Icon(Icons.warning_amber, size: 17, color: Colors.orange),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.orange.shade800,
            ),
          ),
        ),
      ],
    ),
  );
}
