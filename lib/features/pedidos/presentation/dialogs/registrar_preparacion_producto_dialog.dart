import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/producto_consolidado.dart';

class RegistrarPreparacionProductoDialog extends StatefulWidget {
  const RegistrarPreparacionProductoDialog({required this.producto, super.key});

  final ProductoConsolidado producto;

  static Future<PreparacionProductoDraft?> show(
    BuildContext context, {
    required ProductoConsolidado producto,
  }) => showDialog<PreparacionProductoDraft>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => RegistrarPreparacionProductoDialog(producto: producto),
  );

  @override
  State<RegistrarPreparacionProductoDialog> createState() =>
      _RegistrarPreparacionProductoDialogState();
}

class _RegistrarPreparacionProductoDialogState
    extends State<RegistrarPreparacionProductoDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final _observacionController = TextEditingController();
  late final List<_PresentacionEdicion> _presentaciones;
  late final List<_PedidoEdicion> _pedidos;

  @override
  void initState() {
    super.initState();
    _presentaciones = widget.producto.presentaciones
        .map(
          (presentacion) => _PresentacionEdicion(
            resumen: presentacion,
            disponible: widget.producto.disponiblePara(presentacion),
            registrandoAhora: presentacion.pendiente,
          ),
        )
        .toList();
    final pedidos = <String, _PedidoEdicion>{};
    for (final item in widget.producto.distribucion) {
      if (item.cantidadPendientePresentaciones <= 0) continue;
      pedidos
          .putIfAbsent(
            item.pedidoId,
            () => _PedidoEdicion(
              pedidoId: item.pedidoId,
              codigo: item.codigoPedido,
              cliente: item.cliente,
              items: [],
            ),
          )
          .items
          .add(item);
    }
    _pedidos = pedidos.values.toList()
      ..sort((a, b) => a.codigo.compareTo(b.codigo));
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
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth > 900 ? 900 : constraints.maxWidth,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _productoInfo(),
                    const SizedBox(height: 24),
                    _sectionTitle('Productos conseguidos', Icons.inventory),
                    const SizedBox(height: 6),
                    Text(
                      'Las cantidades se registran en la presentación comercial. '
                      'La conversión a unidades es solo informativa.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _presentacionesTable(),
                    const SizedBox(height: 24),
                    _sectionTitle('Pedidos pendientes', Icons.receipt_long),
                    const SizedBox(height: 6),
                    Text(
                      'Un pedido solo puede marcarse cuando están disponibles '
                      'todas las presentaciones pendientes de este producto.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _pedidosList(),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _observacionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación (opcional)',
                        hintText: 'Ej.: se consiguió solo una parte del pedido',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryColor,
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
            'Registrar avance de preparación',
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
  );

  Widget _productoInfo() {
    final producto = widget.producto;
    final imagePath = producto.imagenPath;
    final image = imagePath == null ? null : File(imagePath);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: image != null && image.existsSync()
                ? Image.file(image, fit: BoxFit.cover)
                : const Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: Color(0xFFBDBDBD),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                _infoRow('Código', producto.codigo),
                _infoRow('Marca', producto.marca ?? 'Sin marca'),
                if (producto.variante != 'Producto único')
                  _infoRow('Medida/variante', producto.variante),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presentacionesTable() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: _presentaciones
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final datos = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.resumen.presentacion,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Pendiente: ${item.resumen.pendienteTexto} • '
                        '${item.resumen.factorUnidadBase} '
                        '${unidadBaseTexto(item.resumen.factorUnidadBase, widget.producto.unidadBase)} por presentación',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      if (item.disponible > 0)
                        Text(
                          'Disponible para clasificar: '
                          '${cantidadPresentacionTexto(item.disponible, item.resumen.presentacion)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  );
                  final contador = _contadorPresentacion(item);
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [datos, const SizedBox(height: 10), contador],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: datos),
                      const SizedBox(width: 12),
                      contador,
                    ],
                  );
                },
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _contadorPresentacion(_PresentacionEdicion item) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Registrar ahora',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 8),
      _roundButton(
        Icons.remove,
        item.registrandoAhora > 0
            ? () => _cambiarCantidad(item, item.registrandoAhora - 1)
            : null,
      ),
      SizedBox(
        width: 42,
        child: Text(
          '${item.registrandoAhora}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      _roundButton(
        Icons.add,
        item.registrandoAhora < item.resumen.pendiente
            ? () => _cambiarCantidad(item, item.registrandoAhora + 1)
            : null,
      ),
    ],
  );

  Widget _pedidosList() {
    if (_pedidos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('No existen pedidos pendientes para este producto.'),
      );
    }
    return Column(
      children: _pedidos.map((pedido) {
        final puede = _puedeCompletar(pedido);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: pedido.seleccionado
                ? primaryColor.withValues(alpha: .12)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pedido.seleccionado
                  ? primaryColor
                  : puede
                  ? const Color(0xFFE0E0E0)
                  : Colors.orange.shade200,
              width: pedido.seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final selector = Row(
                    children: [
                      Checkbox(
                        value: pedido.seleccionado,
                        onChanged: puede || pedido.seleccionado
                            ? (value) => _togglePedido(pedido, value ?? false)
                            : null,
                        activeColor: primaryColor,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pedido.codigo,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              pedido.cliente,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final estado = _estadoPedidoChip(
                    pedido.seleccionado
                        ? 'Pedido completo'
                        : puede
                        ? 'Disponible'
                        : 'Faltan presentaciones',
                    pedido.seleccionado
                        ? Colors.green
                        : puede
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                  );
                  if (constraints.maxWidth < 470) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selector,
                        Padding(
                          padding: const EdgeInsets.only(left: 48, top: 4),
                          child: estado,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: selector),
                      const SizedBox(width: 8),
                      estado,
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              ...pedido.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _disponibleRestante(_key(item), excepto: pedido) >=
                                item.cantidadPendientePresentaciones
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 16,
                        color:
                            _disponibleRestante(_key(item), excepto: pedido) >=
                                item.cantidadPendientePresentaciones
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.cantidadPendienteTexto,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      Text(
                        item.equivalenciaSolicitadaTexto,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            icon: const Icon(Icons.check, size: 18),
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

  void _cambiarCantidad(_PresentacionEdicion item, int value) {
    setState(() {
      item.registrandoAhora = value.clamp(0, item.resumen.pendiente);
      for (final pedido in _pedidos) {
        pedido.seleccionado = false;
      }
    });
  }

  bool _puedeCompletar(_PedidoEdicion pedido) => pedido.items.every(
    (item) =>
        _disponibleRestante(_key(item), excepto: pedido) >=
        item.cantidadPendientePresentaciones,
  );

  int _disponibleRestante(String key, {_PedidoEdicion? excepto}) {
    final presentacion = _presentaciones.firstWhere(
      (item) => _keyResumen(item.resumen) == key,
    );
    var disponible = presentacion.disponible + presentacion.registrandoAhora;
    for (final pedido in _pedidos) {
      if (!pedido.seleccionado || identical(pedido, excepto)) continue;
      disponible -= pedido.items
          .where((item) => _key(item) == key)
          .fold(
            0,
            (total, item) => total + item.cantidadPendientePresentaciones,
          );
    }
    return disponible;
  }

  void _togglePedido(_PedidoEdicion pedido, bool selected) {
    if (selected && !_puedeCompletar(pedido)) return;
    setState(() => pedido.seleccionado = selected);
  }

  void _confirmar() {
    final asignaciones = <PreparacionProductoAsignacion>[];
    final asignadoPorPresentacion = <String, int>{};
    for (final pedido in _pedidos.where((item) => item.seleccionado)) {
      for (final item in pedido.items) {
        final cantidad = item.cantidadPendientePresentaciones;
        if (cantidad <= 0) continue;
        asignaciones.add(
          PreparacionProductoAsignacion(
            pedidoItemId: item.pedidoItemId,
            pedidoId: item.pedidoId,
            productoId: widget.producto.productoId,
            cantidad: cantidad,
            presentacion: item.presentacion,
            factorUnidadBase: item.factorUnidadBase,
          ),
        );
        final key = _key(item);
        asignadoPorPresentacion[key] =
            (asignadoPorPresentacion[key] ?? 0) + cantidad;
      }
    }

    final movimientos = _presentaciones
        .map((item) {
          final asignado =
              asignadoPorPresentacion[_keyResumen(item.resumen)] ?? 0;
          return PreparacionDisponibleMovimiento(
            productoId: widget.producto.productoId,
            presentacion: item.resumen.presentacion,
            equivalencia: item.resumen.equivalencia,
            factorUnidadBase: item.resumen.factorUnidadBase,
            cantidadDelta: item.registrandoAhora - asignado,
          );
        })
        .where((item) => item.cantidadDelta != 0)
        .toList();

    if (asignaciones.isEmpty && movimientos.isEmpty) {
      AppNotice.warning(context, 'No hay cantidades para registrar.');
      return;
    }
    Navigator.pop(
      context,
      PreparacionProductoDraft(
        productoKey: widget.producto.key,
        asignaciones: asignaciones,
        movimientosDisponibles: movimientos,
        requierePedidosCompletos: true,
        observacion: _observacionController.text.trim(),
      ),
    );
  }

  String _key(DistribucionPedido item) =>
      '${item.presentacion.trim().toLowerCase()}|${item.factorUnidadBase}';

  String _keyResumen(ResumenPresentacionConsolidada item) =>
      '${item.presentacion.trim().toLowerCase()}|${item.factorUnidadBase}';

  Widget _roundButton(IconData icon, VoidCallback? onPressed) => Material(
    color: primaryColor.withValues(alpha: .15),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : darkColor,
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 20, color: primaryColor),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    ],
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _estadoPedidoChip(String label, Color color) => Container(
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

class _PresentacionEdicion {
  _PresentacionEdicion({
    required this.resumen,
    required this.disponible,
    required this.registrandoAhora,
  });

  final ResumenPresentacionConsolidada resumen;
  final int disponible;
  int registrandoAhora;
}

class _PedidoEdicion {
  _PedidoEdicion({
    required this.pedidoId,
    required this.codigo,
    required this.cliente,
    required this.items,
  });

  final String pedidoId;
  final String codigo;
  final String cliente;
  final List<DistribucionPedido> items;
  bool seleccionado = false;
}
