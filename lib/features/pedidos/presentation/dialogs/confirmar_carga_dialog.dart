import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/producto_consolidado.dart';

class CargaPedidoConfirmada {
  const CargaPedidoConfirmada({
    required this.paquetes,
    required this.observacion,
  });

  final int paquetes;
  final String observacion;
}

class ConfirmarCargaDialog extends StatefulWidget {
  const ConfirmarCargaDialog({required this.pedido, super.key});

  final PedidoPreparacion pedido;

  static Future<CargaPedidoConfirmada?> show(
    BuildContext context, {
    required PedidoPreparacion pedido,
  }) => showDialog<CargaPedidoConfirmada>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => ConfirmarCargaDialog(pedido: pedido),
  );

  @override
  State<ConfirmarCargaDialog> createState() => _ConfirmarCargaDialogState();
}

class _ConfirmarCargaDialogState extends State<ConfirmarCargaDialog> {
  static const _primary = Color(0xFFFFC500);
  static const _dark = Color(0xFF1F1F1F);

  final _observacionController = TextEditingController();
  late int _paquetes;

  @override
  void initState() {
    super.initState();
    _paquetes = widget.pedido.paquetesSugeridos;
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pedidoResumen(),
                    const SizedBox(height: 18),
                    _productosConfirmados(),
                    const SizedBox(height: 18),
                    _presentaciones(),
                    const SizedBox(height: 18),
                    _contadorPaquetes(),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _observacionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación de carga (opcional)',
                        hintText: 'Ej.: carga distribuida en dos paquetes',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_shipping_outlined, color: _dark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmar carga',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _dark,
                ),
              ),
              Text(
                'Verifica el contenido antes de cambiar el estado.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            foregroundColor: Colors.grey,
            backgroundColor: const Color(0xFFF5F5F5),
          ),
        ),
      ],
    ),
  );

  Widget _pedidoResumen() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1F1F),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Marcar el pedido ${widget.pedido.codigo} como cargado?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _datoPedido(Icons.receipt_long, widget.pedido.codigo),
            _datoPedido(Icons.person_outline, widget.pedido.cliente),
          ],
        ),
      ],
    ),
  );

  Widget _productosConfirmados() => Row(
    children: [
      Expanded(
        child: _metric(
          'Productos listos',
          '${widget.pedido.completos}',
          Icons.check_circle_outline,
          Colors.green,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _metric(
          'Total de productos',
          '${widget.pedido.totalProductos}',
          Icons.inventory_2_outlined,
          _primary,
        ),
      ),
    ],
  );

  Widget _presentaciones() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Presentaciones incluidas',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      const SizedBox(height: 10),
      if (widget.pedido.resumenPresentaciones.isEmpty)
        Text(
          'No hay presentaciones preparadas.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF757575),
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.pedido.resumenPresentaciones
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withValues(alpha: .55)),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 8),
      Text(
        'Equivalencia informativa: ${widget.pedido.unidadesPreparadas} '
        '${unidadBaseTexto(widget.pedido.unidadesPreparadas, 'UND')}',
        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF757575)),
      ),
    ],
  );

  Widget _contadorPaquetes() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E5E5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.shopping_bag_outlined, color: _dark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cantidad de paquetes',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              Text(
                'Sugerencia automática; puedes ajustarla.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        _counterButton(
          Icons.remove,
          _paquetes > 1 ? () => setState(() => _paquetes--) : null,
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$_paquetes',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        _counterButton(Icons.add, () => setState(() => _paquetes++)),
      ],
    ),
  );

  Widget _actions() => Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.pedido.tienePendientes ? null : _confirmar,
            icon: const Icon(Icons.local_shipping, size: 18),
            label: const Text('Confirmar carga'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );

  void _confirmar() => Navigator.pop(
    context,
    CargaPedidoConfirmada(
      paquetes: _paquetes,
      observacion: _observacionController.text.trim(),
    ),
  );

  Widget _datoPedido(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _primary),
      const SizedBox(width: 5),
      Text(
        value,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _metric(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _counterButton(IconData icon, VoidCallback? onPressed) => Material(
    color: _primary.withValues(alpha: onPressed == null ? .06 : .18),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : _dark,
        ),
      ),
    ),
  );
}
