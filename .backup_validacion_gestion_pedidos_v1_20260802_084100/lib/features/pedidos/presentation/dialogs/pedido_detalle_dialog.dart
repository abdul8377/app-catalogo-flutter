import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/platform/file_actions_service.dart';
import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/repositories/pedidos_repository.dart';
import 'generar_cotizacion_dialog.dart';
import '../widgets/pedido_estado_badge.dart';

enum PedidoDetalleDialogAction { editar, verCliente }

class PedidoDetalleDialog extends StatefulWidget {
  const PedidoDetalleDialog({required this.pedidoId, super.key});

  final String pedidoId;

  static Future<PedidoDetalleDialogAction?> show(
    BuildContext context, {
    required String pedidoId,
  }) => showDialog<PedidoDetalleDialogAction>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => PedidoDetalleDialog(pedidoId: pedidoId),
  );

  @override
  State<PedidoDetalleDialog> createState() => _PedidoDetalleDialogState();
}

class _PedidoDetalleDialogState extends State<PedidoDetalleDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<PedidoDetalle?> _pedidoFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pedidoFuture = _obtenerPedido();
  }

  Future<PedidoDetalle?> _obtenerPedido() =>
      context.read<PedidosRepository>().obtenerPedidoDetalle(widget.pedidoId);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirCotizacion(String? cotizacionId) async {
    final result = await GenerarCotizacionDialog.show(
      context,
      pedidoId: widget.pedidoId,
      cotizacionId: cotizacionId,
      modoEdicion: cotizacionId != null,
    );
    if (!mounted || result == null) return;
    setState(() {
      _pedidoFuture = _obtenerPedido();
      _tabController.index = 3;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 1120
            ? 1120.0
            : constraints.maxWidth;
        final height = constraints.maxHeight > 900
            ? 900.0
            : constraints.maxHeight;
        return Container(
          width: width,
          height: height,
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
          child: FutureBuilder<PedidoDetalle?>(
            future: _pedidoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PedidoDetalleLoading();
              }
              if (snapshot.hasError) {
                return _PedidoDetalleError(
                  title: 'No se pudo cargar el pedido',
                  message:
                      'Ocurrió un problema leyendo el detalle desde la base local.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              final pedido = snapshot.data;
              if (pedido == null) {
                return _PedidoDetalleError(
                  title: 'Pedido no encontrado',
                  message:
                      'El pedido seleccionado ya no existe en la base local.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              return _PedidoDetalleContent(
                pedido: pedido,
                tabController: _tabController,
                onEditar: () =>
                    Navigator.of(context).pop(PedidoDetalleDialogAction.editar),
                onVerCliente: () => Navigator.of(
                  context,
                ).pop(PedidoDetalleDialogAction.verCliente),
                onAbrirCotizacion: _abrirCotizacion,
                onClose: () => Navigator.of(context).pop(),
              );
            },
          ),
        );
      },
    ),
  );
}

class _PedidoDetalleContent extends StatelessWidget {
  const _PedidoDetalleContent({
    required this.pedido,
    required this.tabController,
    required this.onEditar,
    required this.onVerCliente,
    required this.onAbrirCotizacion,
    required this.onClose,
  });

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final PedidoDetalle pedido;
  final TabController tabController;
  final VoidCallback onEditar;
  final VoidCallback onVerCliente;
  final ValueChanged<String?> onAbrirCotizacion;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Header(pedido: pedido, onClose: onClose),
      TabBar(
        controller: tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Resumen'),
          Tab(text: 'Productos'),
          Tab(text: 'Entrega'),
          Tab(text: 'Cotización'),
          Tab(text: 'Historial'),
        ],
        labelColor: darkColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [
            _ResumenTab(pedido: pedido, onVerCliente: onVerCliente),
            _ProductosTab(pedido: pedido),
            _EntregaTab(pedido: pedido),
            _CotizacionTab(
              pedido: pedido,
              onAbrirCotizacion: onAbrirCotizacion,
            ),
            _HistorialTab(historial: pedido.historial),
          ],
        ),
      ),
      _ActionsBar(
        onClose: onClose,
        onEditar: onEditar,
        puedeEditar:
            pedido.estadoNormalizado != 'cancelado' &&
            pedido.estadoNormalizado != 'entregado',
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.pedido, required this.onClose});

  static const darkColor = Color(0xFF1F1F1F);

  final PedidoDetalle pedido;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final estadoColor = pedidoEstadoColor(pedido.estadoNormalizado);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pedido.codigo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: darkColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 22),
                splashRadius: 20,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.grey,
                  backgroundColor: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Badge(label: pedido.estadoLabel, color: estadoColor),
              _Badge(
                label: pedido.sincronizado
                    ? 'Sincronizado'
                    : pedido.guardadoLocal
                    ? 'Guardado local'
                    : 'Sin sinc',
                color: pedido.sincronizado
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
              ),
              Text(
                '${pedido.clienteNombre} • ${_formatFechaHora(pedido.fecha)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenTab extends StatelessWidget {
  const _ResumenTab({required this.pedido, required this.onVerCliente});

  final PedidoDetalle pedido;
  final VoidCallback onVerCliente;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Cliente'),
        const SizedBox(height: 8),
        _ClienteCard(pedido: pedido, onVerCliente: onVerCliente),
        const SizedBox(height: 20),
        const _SectionTitle('Pedido'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: [
            _InfoRow(label: 'Código', value: pedido.codigo),
            _InfoRow(label: 'Fecha', value: _formatFecha(pedido.fecha)),
            _InfoRow(label: 'Hora', value: _formatHora(pedido.fecha)),
            _InfoRow(label: 'Hoja', value: pedido.hoja),
            _InfoRow(label: 'Vendedor', value: pedido.vendedor),
            _InfoRow(label: 'Estado', value: pedido.estadoLabel),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Información económica'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: pedido.cotizacionVigente
              ? [
                  _InfoRow(
                    label: 'Subtotal de productos',
                    value: 'S/ ${pedido.subtotalProductos.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Descuento',
                    value:
                        '- S/ ${pedido.descuentoCotizado.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Total sin IGV',
                    value: 'S/ ${pedido.totalSinIgv.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'IGV',
                    value: 'S/ ${pedido.igv.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Total de cotización',
                    value: 'S/ ${pedido.totalFinal.toStringAsFixed(2)}',
                  ),
                ]
              : pedido.productosSinPrecio == 0
              ? [
                  _InfoRow(
                    label: 'Subtotal conocido',
                    value: 'S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Total',
                    value: 'S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
                  ),
                ]
              : [
                  _InfoRow(
                    label: 'Subtotal conocido',
                    value: 'S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Productos sin precio',
                    value: '${pedido.productosSinPrecio} pendiente(s)',
                  ),
                  const _InfoRow(
                    label: 'Total final',
                    value: 'Pendiente de valorización',
                  ),
                ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Estado operativo'),
        const SizedBox(height: 8),
        _InfoCard(
          rows: [
            _InfoRow(
              label: 'Preparación',
              value: pedido.estadoPreparacionLabel,
            ),
            _InfoRow(label: 'Carga', value: pedido.estadoCargaLabel),
            _InfoRow(
              label: 'Sincronización',
              value: pedido.sincronizado ? 'Sincronizado' : 'Pendiente',
            ),
            _InfoRow(
              label: 'Cotización',
              value: pedido.cotizacionCodigo ?? 'No generada',
            ),
          ],
        ),
      ],
    ),
  );
}

class _ClienteCard extends StatelessWidget {
  const _ClienteCard({required this.pedido, required this.onVerCliente});

  final PedidoDetalle pedido;
  final VoidCallback onVerCliente;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC500).withValues(alpha: .2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  pedido.clienteNombre.isNotEmpty
                      ? pedido.clienteNombre[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.clienteNombre,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  if (pedido.clienteRuc.isNotEmpty)
                    Text(
                      'RUC: ${pedido.clienteRuc}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  if (pedido.clienteDni.isNotEmpty)
                    Text(
                      'DNI: ${pedido.clienteDni}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onVerCliente,
              icon: const Icon(Icons.person, size: 16),
              label: const Text('Ver ficha completa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F1F1F),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(
                context,
                pedido.telefono,
                'Teléfono copiado',
              ),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(pedido.telefono),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProductosTab extends StatelessWidget {
  const _ProductosTab({required this.pedido});

  final PedidoDetalle pedido;

  @override
  Widget build(BuildContext context) {
    if (pedido.productos.isEmpty) {
      return const _EmptyTab(
        icon: Icons.inventory_2_outlined,
        title: 'Sin productos',
        message: 'Este pedido no tiene productos registrados.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pedido.productos.length,
      itemBuilder: (_, i) =>
          _ProductoDetalleCard(producto: pedido.productos[i]),
    );
  }
}

class _ProductoDetalleCard extends StatelessWidget {
  const _ProductoDetalleCard({required this.producto});

  final PedidoDetalleProducto producto;

  @override
  Widget build(BuildContext context) {
    final tienePrecio = producto.tienePrecio;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tienePrecio ? Colors.white : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tienePrecio
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFFFC500).withValues(alpha: .6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProductoImage(path: producto.imagenPath),
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
                    Text(
                      'Código: ${producto.codigo}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    if ((producto.marca ?? '').isNotEmpty)
                      Text(
                        producto.marca!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                  ],
                ),
              ),
              if (!tienePrecio)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sin precio',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ProductDetailRow(
            label: 'Presentación',
            value: producto.presentacion,
          ),
          _ProductDetailRow(
            label: 'Cantidad',
            value: '${producto.cantidad} ${producto.presentacion}',
          ),
          if (producto.equivalencia.isNotEmpty)
            _ProductDetailRow(
              label: 'Equivalencia',
              value: producto.equivalenciaTotal,
            ),
          if (tienePrecio)
            _ProductDetailRow(
              label: 'Precio',
              value:
                  'S/ ${producto.precioUnitario!.toStringAsFixed(2)} por ${producto.presentacion}',
            ),
          _ProductDetailRow(
            label: 'Subtotal',
            value: tienePrecio
                ? 'S/ ${(producto.subtotal ?? 0).toStringAsFixed(2)}'
                : 'Pendiente',
          ),
        ],
      ),
    );
  }
}

class _EntregaTab extends StatelessWidget {
  const _EntregaTab({required this.pedido});

  final PedidoDetalle pedido;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          rows: [
            _InfoRow(label: 'Cliente', value: pedido.clienteNombre),
            _InfoRow(label: 'Teléfono', value: pedido.telefono),
            _InfoRow(
              label: 'Dirección',
              value: pedido.direccion.isEmpty
                  ? 'Dirección no especificada'
                  : pedido.direccion,
            ),
            if (pedido.referencia.isNotEmpty)
              _InfoRow(label: 'Referencia', value: pedido.referencia),
          ],
        ),
        const SizedBox(height: 16),
        _FotoUbicacion(path: pedido.fotoUbicacionPath),
        if (pedido.observacionesEntrega.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InfoCard(
            rows: [
              _InfoRow(
                label: 'Observaciones',
                value: pedido.observacionesEntrega,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final copiarDireccion = OutlinedButton.icon(
              onPressed: pedido.direccion.isEmpty
                  ? null
                  : () => _copyToClipboard(
                      context,
                      pedido.direccion,
                      'Dirección copiada',
                    ),
              icon: const Icon(Icons.copy),
              label: const Text('Copiar dirección'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
            );
            final copiarTelefono = OutlinedButton.icon(
              onPressed: pedido.telefono.isEmpty
                  ? null
                  : () => _copyToClipboard(
                      context,
                      pedido.telefono,
                      'Teléfono copiado',
                    ),
              icon: const Icon(Icons.phone),
              label: const Text('Copiar teléfono'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
            );
            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copiarDireccion,
                  const SizedBox(height: 8),
                  copiarTelefono,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: copiarDireccion),
                const SizedBox(width: 8),
                Expanded(child: copiarTelefono),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _CotizacionTab extends StatelessWidget {
  const _CotizacionTab({required this.pedido, required this.onAbrirCotizacion});

  final PedidoDetalle pedido;
  final ValueChanged<String?> onAbrirCotizacion;

  @override
  Widget build(BuildContext context) {
    final cotizaciones = pedido.cotizaciones;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cotizaciones del pedido',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pulsa una versión para abrirla. Las generadas crean '
                      'una nueva versión al guardar.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => onAbrirCotizacion(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva cotización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC500),
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: cotizaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay cotizaciones guardadas',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  itemCount: cotizaciones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final quote = cotizaciones[index];
                    final path = quote.pdfPath;
                    final hasPdf =
                        path != null &&
                        path.isNotEmpty &&
                        File(path).existsSync();
                    return _CotizacionHistorialCard(
                      cotizacion: quote,
                      onTap: () => onAbrirCotizacion(quote.id),
                      onOpenPdf: hasPdf
                          ? () => _runFileAction(
                              context,
                              () => FileActionsService.openPdf(path),
                            )
                          : null,
                      onSharePdf: hasPdf
                          ? () => _runFileAction(
                              context,
                              () => FileActionsService.sharePdf(path),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _runFileAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      AppNotice.error(context, 'No se pudo abrir el PDF: $error');
    }
  }
}

class _CotizacionHistorialCard extends StatelessWidget {
  const _CotizacionHistorialCard({
    required this.cotizacion,
    required this.onTap,
    this.onOpenPdf,
    this.onSharePdf,
  });

  final CotizacionPedidoGuardada cotizacion;
  final VoidCallback onTap;
  final VoidCallback? onOpenPdf;
  final VoidCallback? onSharePdf;

  @override
  Widget build(BuildContext context) {
    final statusColor = cotizacion.esBorrador
        ? Colors.orange
        : cotizacion.esGenerada
        ? Colors.green
        : Colors.blueGrey;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('abrir_cotizacion_${cotizacion.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E3E3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC500).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cotizacion.esBorrador
                      ? Icons.edit_note_outlined
                      : Icons.description_outlined,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cotizacion.codigoVersion,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatFecha(cotizacion.creadoEn)} • '
                      'S/ ${cotizacion.total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF757575),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenPdf != null)
                IconButton(
                  tooltip: 'Ver PDF',
                  onPressed: onOpenPdf,
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                ),
              if (onSharePdf != null)
                IconButton(
                  tooltip: 'Compartir PDF',
                  onPressed: onSharePdf,
                  icon: const Icon(Icons.share_outlined, size: 20),
                ),
              _Badge(label: cotizacion.estado, color: statusColor),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorialTab extends StatelessWidget {
  const _HistorialTab({required this.historial});

  final List<PedidoHistorialEntrada> historial;

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return const _EmptyTab(
        icon: Icons.history,
        title: 'Sin historial',
        message: 'Todavía no hay movimientos registrados para este pedido.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historial.length,
      itemBuilder: (_, i) {
        final entry = historial[i];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? const Color(0xFFFFC500)
                            : Colors.grey.shade300,
                      ),
                    ),
                    if (i < historial.length - 1)
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade200),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFechaHora(entry.fecha),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.evento,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if ((entry.responsable ?? '').isNotEmpty)
                        Text(
                          'Por: ${entry.responsable}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.onClose,
    required this.onEditar,
    required this.puedeEditar,
  });

  static const primaryColor = Color(0xFFFFC500);

  final VoidCallback onClose;
  final VoidCallback onEditar;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      border: const Border(top: BorderSide(color: Color(0xFFE1E5EA))),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              child: const Text('Cerrar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const Key('editar_pedido_desde_detalle'),
              onPressed: puedeEditar ? onEditar : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(puedeEditar ? 'Editar pedido' : 'Pedido no editable'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 46),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton._({
    required this.label,
    required this.onPressed,
    required this.outlined,
    this.color,
    this.foreground,
  });

  factory _DialogActionButton.outlined({
    required String label,
    required VoidCallback onPressed,
  }) =>
      _DialogActionButton._(label: label, onPressed: onPressed, outlined: true);

  factory _DialogActionButton.filled({
    required String label,
    required Color color,
    required Color foreground,
    required VoidCallback onPressed,
  }) => _DialogActionButton._(
    label: label,
    onPressed: onPressed,
    outlined: false,
    color: color,
    foreground: foreground,
  );

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: row,
            ),
          )
          .toList(),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 128,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF757575),
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC500),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

class _ProductoImage extends StatelessWidget {
  const _ProductoImage({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        color: const Color(0xFFF5F5F5),
        child: imagePath == null || imagePath.isEmpty
            ? const Icon(Icons.image, color: Color(0xFFBDBDBD))
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
      ),
    );
  }
}

class _FotoUbicacion extends StatelessWidget {
  const _FotoUbicacion({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final foto = path;
    if (foto == null || foto.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin fotografía de ubicación',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280, maxHeight: 430),
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: const Color(0xFFF3F3F3),
        child: Image.file(
          File(foto),
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          ),
        ],
      ),
    ),
  );
}

class _PedidoDetalleLoading extends StatelessWidget {
  const _PedidoDetalleLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Color(0xFFFFC500)));
}

class _PedidoDetalleError extends StatelessWidget {
  const _PedidoDetalleError({
    required this.title,
    required this.message,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _copyToClipboard(
  BuildContext context,
  String value,
  String message,
) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  AppNotice.info(context, message);
}

String _formatFecha(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

String _formatHora(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _formatFechaHora(DateTime dt) =>
    '${_formatFecha(dt)} • ${_formatHora(dt)}';
