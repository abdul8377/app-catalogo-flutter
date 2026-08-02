import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/pedido_resumen.dart';
import '../bloc/pedidos_listado_bloc.dart';
import '../bloc/pedidos_listado_event.dart';
import '../bloc/pedidos_listado_state.dart';
import '../dialogs/cambiar_estado_dialog.dart';
import '../dialogs/cancelar_pedido_dialog.dart';
import '../dialogs/generar_cotizacion_dialog.dart';
import '../dialogs/pedido_detalle_dialog.dart';
import '../widgets/estados_vacios.dart';
import '../widgets/pedido_card.dart';
import '../widgets/pedido_estado_badge.dart';
import '../widgets/pedido_sync_badge.dart';
import '../widgets/pedidos_buscador.dart';
import '../widgets/pedidos_filtros.dart';
import '../widgets/pedidos_resumen_estados.dart';

class PedidosListadoView extends StatefulWidget {
  const PedidosListadoView({
    required this.vistaLista,
    this.onOpenCliente,
    this.onOpenHoja,
    super.key,
  });

  final bool vistaLista;
  final ValueChanged<String>? onOpenCliente;
  final ValueChanged<String>? onOpenHoja;

  @override
  State<PedidosListadoView> createState() => _PedidosListadoViewState();
}

class _PedidosListadoViewState extends State<PedidosListadoView> {
  String? _selectedPedidoId;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PedidosListadoBloc, PedidosListadoState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.message != current.message,
        listener: (context, state) {
          final text = state.error ?? state.message;
          if (text == null) return;
          if (state.error != null) {
            AppNotice.error(context, text);
          } else {
            AppNotice.success(context, text);
          }
        },
        builder: (context, state) {
          final pedidos = state.pedidosFiltrados;
          return Column(
            children: [
              PedidosResumenEstados(
                state: state,
                onTap: (filtro) => context.read<PedidosListadoBloc>().add(
                  PedidosListadoFiltroRapidoCambiado(filtro),
                ),
              ),
              PedidosBuscador(
                busqueda: state.busqueda,
                onChanged: (value) => context.read<PedidosListadoBloc>().add(
                  PedidosListadoBusquedaCambiada(value),
                ),
              ),
              PedidosFiltros(
                state: state,
                resultados: pedidos.length,
                onFiltroRapido: (filtro) => context
                    .read<PedidosListadoBloc>()
                    .add(PedidosListadoFiltroRapidoCambiado(filtro)),
                onFiltrosAvanzados: (filtros) =>
                    context.read<PedidosListadoBloc>().add(
                      PedidosListadoFiltrosAvanzadosAplicados(
                        estado: filtros.estado,
                        hoja: filtros.hoja,
                        precio: filtros.precio,
                        sincronizacion: filtros.sincronizacion,
                        fechaInicio: filtros.fechaInicio,
                        fechaFin: filtros.fechaFin,
                        cliente: filtros.cliente,
                        vendedor: filtros.vendedor,
                        empresa: filtros.empresa,
                        categoria: filtros.categoria,
                        producto: filtros.producto,
                        cotizacion: filtros.cotizacion,
                      ),
                    ),
                onOrdenChanged: (orden) => context
                    .read<PedidosListadoBloc>()
                    .add(PedidosListadoOrdenCambiado(orden)),
                onLimpiarFiltros: () => context.read<PedidosListadoBloc>().add(
                  const PedidosListadoFiltrosLimpiados(),
                ),
              ),
              Expanded(child: _contenido(context, state, pedidos)),
            ],
          );
        },
      );

  Widget _contenido(
    BuildContext context,
    PedidosListadoState state,
    List<PedidoResumen> pedidos,
  ) {
    if (state.loading) return const _PedidosLoadingSkeleton();
    if (pedidos.isEmpty) {
      return EstadoVacioPedidos(
        icon: Icons.receipt_long,
        title: 'No se encontraron pedidos',
        message: state.pedidos.isEmpty
            ? 'Aún no hay pedidos registrados. Cuando confirmes pedidos desde el carrito aparecerán aquí.'
            : 'Prueba cambiando la búsqueda o limpiando los filtros aplicados.',
        actionLabel: state.pedidos.isEmpty ? null : 'Limpiar filtros',
        onAction: state.pedidos.isEmpty
            ? null
            : () => context.read<PedidosListadoBloc>().add(
                const PedidosListadoFiltrosLimpiados(),
              ),
      );
    }

    if (!widget.vistaLista) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 840) {
            return _listaPedidos(pedidos);
          }
          final selected = _pedidoSeleccionado(pedidos);
          final detalle = selected ?? pedidos.first;
          return Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * .55,
                child: _listaPedidos(pedidos),
              ),
              const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
              Expanded(child: _DetalleRapidoPedido(pedido: detalle)),
            ],
          );
        },
      );
    }

    return _listaPedidos(pedidos);
  }

  PedidoResumen? _pedidoSeleccionado(List<PedidoResumen> pedidos) {
    for (final pedido in pedidos) {
      if (pedido.id == _selectedPedidoId) return pedido;
    }
    return null;
  }

  Widget _listaPedidos(List<PedidoResumen> pedidos) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: pedidos.length,
    itemBuilder: (context, index) {
      final pedido = pedidos[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PedidoCard(
          pedido: pedido,
          onVerPedido: () {
            setState(() => _selectedPedidoId = pedido.id);
            _mostrarDetallePedido(pedido);
          },
          onCambiarEstado: () => pedido.estadoNormalizado == 'cancelado'
              ? _mostrarReactivarPedido(pedido)
              : _mostrarCambiarEstado(pedido),
          onMenuSelected: (value) {
            if (value == 'cotizacion') {
              _mostrarCotizacionPedido(pedido);
              return;
            }
            if (value == 'cancelar') {
              _mostrarCancelarPedido(pedido);
              return;
            }
            if (value == 'cliente') {
              widget.onOpenCliente?.call(pedido.clienteId);
              return;
            }
            if (value == 'hoja') {
              widget.onOpenHoja?.call(pedido.hojaCodigo);
              return;
            }
            if (value == 'editar_pedido') {
              _editarPedido(pedido);
              return;
            }
            if (value == 'reactivar') {
              _mostrarReactivarPedido(pedido);
              return;
            }
            if (value == 'sync') {
              context.read<PedidosListadoBloc>().add(
                PedidosListadoSincronizacionReintentada(pedido.id),
              );
            }
          },
        ),
      );
    },
  );

  Future<void> _mostrarDetallePedido(PedidoResumen pedido) async {
    final action = await PedidoDetalleDialog.show(context, pedidoId: pedido.id);
    if (!mounted || action == null) return;
    switch (action) {
      case PedidoDetalleDialogAction.editar:
        await _editarPedido(pedido);
      case PedidoDetalleDialogAction.verCliente:
        widget.onOpenCliente?.call(pedido.clienteId);
    }
  }

  Future<void> _editarPedido(PedidoResumen pedido) async {
    if (pedido.estadoNormalizado == 'cancelado') {
      AppNotice.warning(
        context,
        'Reactiva el pedido antes de editar sus productos.',
      );
      return;
    }
    if (pedido.estadoNormalizado == 'entregado') {
      AppNotice.warning(context, 'Un pedido entregado no puede modificarse.');
      return;
    }
    AppNotice.info(
      context,
      'La edición de productos se aplicará en la siguiente fase de esta corrección.',
    );
  }

  Future<void> _mostrarCotizacionPedido(
    PedidoResumen pedido, {
    bool modoEdicion = false,
  }) async {
    final cotizacion = await GenerarCotizacionDialog.show(
      context,
      pedidoId: pedido.id,
      modoEdicion: modoEdicion,
    );
    if (!mounted || cotizacion == null) return;
    context.read<PedidosListadoBloc>().add(const PedidosListadoRecargado());
    final pdfMessage = cotizacion.pdfPath == null
        ? ''
        : ' PDF: ${cotizacion.pdfPath}';
    final tipoGuardado = cotizacion.estado == 'Borrador'
        ? 'Borrador ${cotizacion.codigo} guardado'
        : 'Cotización ${cotizacion.codigo} generada';
    AppNotice.success(
      context,
      '$tipoGuardado por S/ ${cotizacion.total.toStringAsFixed(2)}.$pdfMessage',
    );
  }

  Future<void> _mostrarCambiarEstado(PedidoResumen pedido) async {
    final result = await CambiarEstadoDialog.show(
      context,
      estadoActual: pedido.estado,
      permitirCambioAdministrativo: true,
    );
    if (!mounted || result == null) return;
    final confirmado = await _confirmarCambioEstado(pedido, result.nuevoEstado);
    if (!mounted || !confirmado) return;
    context.read<PedidosListadoBloc>().add(
      PedidosListadoEstadoActualizado(
        pedidoId: pedido.id,
        nuevoEstado: result.nuevoEstado,
        observacion: result.observacion,
      ),
    );
  }

  Future<void> _mostrarReactivarPedido(PedidoResumen pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF2E7D32)),
        title: const Text('Reactivar pedido'),
        content: const Text(
          'El pedido volverá a Pendiente. Se conservarán sus productos, '
          'cotizaciones e historial, pero se limpiarán avances de '
          'preparación y carga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.read<PedidosListadoBloc>().add(
      PedidosListadoPedidoReactivado(pedidoId: pedido.id),
    );
  }

  Future<void> _mostrarCancelarPedido(PedidoResumen pedido) async {
    final motivo = await CancelarPedidoDialog.show(context);
    if (!mounted || motivo == null) return;
    context.read<PedidosListadoBloc>().add(
      PedidosListadoPedidoCancelado(pedidoId: pedido.id, motivo: motivo),
    );
  }

  Future<bool> _confirmarCambioEstado(
    PedidoResumen pedido,
    String nuevoEstado,
  ) async {
    final actual = _estadoIndice(pedido.estado);
    final nuevo = _estadoIndice(nuevoEstado);
    final retroceso = nuevo < actual;
    final modificaOperacion =
        nuevoEstado == 'Pendiente' ||
        nuevoEstado == 'Listo para entregar' ||
        nuevoEstado == 'Entregado';
    if (!retroceso && !modificaOperacion) return true;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          retroceso ? Icons.history : Icons.sync_alt,
          color: const Color(0xFFF57C00),
        ),
        title: Text(
          retroceso ? 'Confirmar retroceso de estado' : 'Confirmar operación',
        ),
        content: Text(
          nuevoEstado == 'Pendiente'
              ? 'Se desactivarán los avances actuales de preparación y carga. El historial se conservará.'
              : nuevoEstado == 'Listo para entregar'
              ? 'Se completarán la preparación y la carga del pedido.'
              : nuevoEstado == 'Entregado'
              ? 'Se completarán los pasos operativos previos y se registrará la entrega.'
              : 'El pedido volverá a un estado anterior. El historial se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  int _estadoIndice(String estado) {
    final value = estado.toLowerCase();
    if (value.contains('entregado')) return 3;
    if (value.contains('listo')) return 2;
    if (value.contains('proceso')) return 1;
    return 0;
  }
}

class _DetalleRapidoPedido extends StatelessWidget {
  const _DetalleRapidoPedido({required this.pedido});

  final PedidoResumen pedido;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
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
                  pedido.codigo,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              PedidoEstadoBadge(pedido: pedido),
            ],
          ),
          const SizedBox(height: 8),
          PedidoSyncBadge(pedido: pedido),
          const Divider(height: 28),
          _section('Cliente'),
          _text(pedido.clienteNombre, bold: true),
          _text('Teléfono: ${pedido.telefono}'),
          if (pedido.ruc.isNotEmpty) _text('RUC: ${pedido.ruc}'),
          if (pedido.dni.isNotEmpty) _text('DNI: ${pedido.dni}'),
          const SizedBox(height: 16),
          _section('Entrega'),
          _text(
            pedido.direccion.isEmpty
                ? 'Dirección no especificada'
                : pedido.direccion,
            bold: true,
          ),
          if (pedido.referencia.isNotEmpty) _text(pedido.referencia),
          const SizedBox(height: 16),
          _section('Productos'),
          _text(
            '${pedido.cantidadProductos} productos • ${pedido.cantidadPresentaciones} presentaciones',
          ),
          _text(pedido.productosTexto),
          const SizedBox(height: 16),
          _section('Totales'),
          if (pedido.cotizacionVigente) ...[
            _text(
              'Subtotal sin IGV: S/ ${pedido.totalSinIgv.toStringAsFixed(2)}',
            ),
            _text('IGV (18 %): S/ ${pedido.igv.toStringAsFixed(2)}'),
            _text(
              'Total: S/ ${pedido.totalCotizado.toStringAsFixed(2)}',
              bold: true,
            ),
          ] else ...[
            _text(
              'Subtotal conocido: S/ ${pedido.subtotalConocido.toStringAsFixed(2)}',
              bold: true,
            ),
            if (pedido.productosSinPrecio > 0)
              _text(
                '${pedido.productosSinPrecio} pendiente(s) de valorización',
              ),
          ],
          const SizedBox(height: 16),
          _section('Hoja'),
          _text(pedido.hojaCodigo),
        ],
      ),
    ),
  );

  Widget _section(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF757575),
      ),
    ),
  );

  Widget _text(String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      value,
      style: GoogleFonts.inter(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: const Color(0xFF1F1F1F),
      ),
    ),
  );
}

class _PedidosLoadingSkeleton extends StatelessWidget {
  const _PedidosLoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, _) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    ),
  );
}
