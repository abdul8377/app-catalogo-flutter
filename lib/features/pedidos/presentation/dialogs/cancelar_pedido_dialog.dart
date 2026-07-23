import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CancelarPedidoDialog extends StatefulWidget {
  const CancelarPedidoDialog({super.key});

  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const CancelarPedidoDialog(),
  );

  @override
  State<CancelarPedidoDialog> createState() => _CancelarPedidoDialogState();
}

class _CancelarPedidoDialogState extends State<CancelarPedidoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancelar pedido',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'El pedido dejará de formar parte del flujo activo. La información y el historial se conservarán.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF616161),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de cancelación *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingrese un motivo'
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _cancelarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  child: const Text('Cancelar pedido'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  void _cancelarPedido() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_motivoController.text.trim());
  }
}
