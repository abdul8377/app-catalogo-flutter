import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/producto_consolidado.dart';

class RegistrarPreparacionDialog extends StatefulWidget {
  const RegistrarPreparacionDialog({required this.pedido, super.key});

  final PedidoPreparacion pedido;

  static Future<PreparacionProductoDraft?> show(
    BuildContext context, {
    required PedidoPreparacion pedido,
  }) => showDialog<PreparacionProductoDraft>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => RegistrarPreparacionDialog(pedido: pedido),
  );

  @override
  State<RegistrarPreparacionDialog> createState() =>
      _RegistrarPreparacionDialogState();
}

class _RegistrarPreparacionDialogState
    extends State<RegistrarPreparacionDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final _observacionController = TextEditingController();
  late final List<_ItemPreparacion> _items;

  @override
  void initState() {
    super.initState();
    _items =
        widget.pedido.productos
            .map(
              (producto) => _ItemPreparacion(
                producto: producto,
                cantidadAhora: producto.pendiente,
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.producto.completado == b.producto.completado) {
              return a.producto.nombre.compareTo(b.producto.nombre);
            }
            return a.producto.completado ? 1 : -1;
          });
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  int get _completos => _items
      .where(
        (item) =>
            item.producto.completado ||
            (item.producto.pendiente > 0 &&
                item.cantidadAhora == item.producto.pendiente),
      )
      .length;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth > 930 ? 930 : constraints.maxWidth,
        height: constraints.maxHeight > 820 ? 820 : constraints.maxHeight,
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
          children: [
            _header(),
            _quickActions(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _items.length,
                itemBuilder: (_, index) => _productoCard(_items[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: TextField(
                controller: _observacionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observación de la preparación (opcional)',
                  hintText: 'Ej.: caja deteriorada o producto incompleto',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    ),
  );

  Widget _header() {
    final pedido = widget.pedido;
    final total = _items.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registrar preparación del pedido',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: darkColor,
                  ),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _headerData(Icons.tag, pedido.codigo),
              _headerData(Icons.person, pedido.cliente),
              if (pedido.empresa.isNotEmpty)
                _headerData(Icons.business, pedido.empresa),
              if (pedido.zonaAlmacen.isNotEmpty)
                _headerData(Icons.warehouse, pedido.zonaAlmacen),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Progreso: $_completos de $total productos',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : _completos / total,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      _completos == total ? Colors.green : primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() {
            for (final item in _items) {
              item.cantidadAhora = item.producto.pendiente;
            }
          }),
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Preparar todo lo pendiente'),
          style: TextButton.styleFrom(foregroundColor: darkColor),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() {
            for (final item in _items) {
              item.cantidadAhora = 0;
            }
          }),
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('Limpiar selección'),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        ),
      ],
    ),
  );

  Widget _productoCard(_ItemPreparacion item) {
    final producto = item.producto;
    final pendiente = producto.pendiente;
    final completoOperacion = pendiente > 0 && item.cantidadAhora == pendiente;
    final parcial = item.cantidadAhora > 0 && item.cantidadAhora < pendiente;
    final imagePath = producto.imagenPath;
    final image = imagePath == null ? null : File(imagePath);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completoOperacion
            ? primaryColor.withValues(alpha: .15)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completoOperacion
              ? primaryColor
              : parcial
              ? primaryColor.withValues(alpha: .65)
              : const Color(0xFFE0E0E0),
          width: completoOperacion || parcial ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: producto.completado || completoOperacion,
                onChanged: producto.completado
                    ? null
                    : (selected) => setState(
                        () => item.cantidadAhora = selected == true
                            ? pendiente
                            : 0,
                      ),
                activeColor: primaryColor,
                checkColor: Colors.black,
              ),
              Container(
                width: 58,
                height: 58,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: image != null && image.existsSync()
                    ? Image.file(image, fit: BoxFit.cover)
                    : const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFBDBDBD),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (producto.variante.isNotEmpty &&
                        producto.variante != 'Producto único')
                      Text(
                        producto.variante,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      'Código: ${producto.codigo}'
                      '${producto.marca.isEmpty ? '' : ' • ${producto.marca}'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              if (producto.completado || completoOperacion)
                _statusChip('Completo', Colors.green)
              else if (parcial)
                _statusChip('Preparación parcial', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 5,
            children: [
              _quantity('Presentación', producto.presentacion),
              _quantity('Solicitado', producto.solicitadoTexto),
              _quantity('Preparado anteriormente', producto.preparadoTexto),
              _quantity(
                'Pendiente',
                producto.pendienteTexto,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendiente > 0)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Preparar ahora:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                _roundButton(
                  Icons.remove,
                  item.cantidadAhora > 0
                      ? () => _change(item, item.cantidadAhora - 1)
                      : null,
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${item.cantidadAhora}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _roundButton(
                  Icons.add,
                  item.cantidadAhora < pendiente
                      ? () => _change(item, item.cantidadAhora + 1)
                      : null,
                ),
                Text(
                  cantidadPresentacionTexto(
                    item.cantidadAhora,
                    producto.presentacion,
                  ).replaceFirst('${item.cantidadAhora} ', ''),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          if (parcial) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Quedará pendiente: ${cantidadPresentacionTexto(pendiente - item.cantidadAhora, producto.presentacion)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 7),
          Text(
            'Equivalencia informativa: ${producto.equivalenciaTexto}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

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
              foregroundColor: darkColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmar,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar preparación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );

  void _change(_ItemPreparacion item, int value) {
    setState(
      () => item.cantidadAhora = value.clamp(0, item.producto.pendiente),
    );
  }

  void _confirmar() {
    final asignaciones = _items
        .where((item) => item.cantidadAhora > 0)
        .map(
          (item) => PreparacionProductoAsignacion(
            pedidoItemId: item.producto.pedidoItemId,
            pedidoId: widget.pedido.id,
            productoId: item.producto.productoId,
            cantidad: item.cantidadAhora,
            presentacion: item.producto.presentacion,
            factorUnidadBase: item.producto.factorUnidadBase,
          ),
        )
        .toList();
    if (asignaciones.isEmpty) {
      AppNotice.warning(
        context,
        'Selecciona al menos una cantidad para preparar.',
      );
      return;
    }
    Navigator.pop(
      context,
      PreparacionProductoDraft(
        productoKey: 'pedido:${widget.pedido.id}',
        asignaciones: asignaciones,
        observacion: _observacionController.text.trim(),
      ),
    );
  }

  Widget _headerData(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF757575)),
      const SizedBox(width: 4),
      Text(
        value,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _roundButton(IconData icon, VoidCallback? action) => Material(
    color: primaryColor.withValues(alpha: .15),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: action == null ? Colors.grey : darkColor,
        ),
      ),
    ),
  );

  Widget _quantity(String label, String value, {Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _ItemPreparacion {
  _ItemPreparacion({required this.producto, required this.cantidadAhora});

  final ProductoPreparacion producto;
  int cantidadAhora;
}
