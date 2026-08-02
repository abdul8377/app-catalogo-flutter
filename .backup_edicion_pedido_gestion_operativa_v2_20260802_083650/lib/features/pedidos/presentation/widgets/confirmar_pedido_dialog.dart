import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../../clientes/domain/entities/cliente.dart' as clientes_domain;
import '../../../clientes/domain/entities/nuevo_cliente.dart';
import '../../../clientes/domain/repositories/clientes_repository.dart';
import '../../../clientes/presentation/widgets/cliente_formulario.dart';
import '../../../clientes/presentation/widgets/cliente_selector.dart';
import '../../domain/entities/pedido.dart';
import '../bloc/pedidos_bloc.dart';
import '../bloc/pedidos_event.dart';
import '../bloc/pedidos_state.dart';

class ConfirmarPedidoDialog extends StatefulWidget {
  const ConfirmarPedidoDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final pedidosBloc = context.read<PedidosBloc>();
    final clientesRepository = context.read<ClientesRepository>();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (_) => RepositoryProvider<ClientesRepository>.value(
            value: clientesRepository,
            child: BlocProvider<PedidosBloc>.value(
              value: pedidosBloc,
              child: const ConfirmarPedidoDialog(),
            ),
          ),
        ) ??
        false;
  }

  @override
  State<ConfirmarPedidoDialog> createState() => _ConfirmarPedidoDialogState();
}

class _ConfirmarPedidoDialogState extends State<ConfirmarPedidoDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final _clienteFormKey = GlobalKey<ClienteFormularioState>();
  int _paso = 0;

  @override
  Widget build(BuildContext context) => BlocConsumer<PedidosBloc, PedidosState>(
    listenWhen: (previous, current) =>
        previous.resultado != current.resultado && current.resultado != null,
    listener: (context, state) => Navigator.pop(context, true),
    builder: (context, state) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 1180
              ? 1180.0
              : constraints.maxWidth * .96;
          final height = constraints.maxHeight > 920
              ? 920.0
              : constraints.maxHeight * .94;
          return Container(
            key: const Key('confirmar_pedido_dialog_surface'),
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
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  _header(context),
                  _stepper(),
                  if (state.error != null) _error(state.error!),
                  Expanded(
                    child: IndexedStack(
                      index: _paso,
                      children: [
                        _buildPasoProductos(state),
                        _buildPasoCliente(state),
                        _buildPasoConfirmacion(state),
                      ],
                    ),
                  ),
                  _acciones(state),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    color: darkColor,
    padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _paso == 0
                ? Icons.shopping_cart_checkout_rounded
                : _paso == 1
                ? Icons.person_outline_rounded
                : Icons.fact_check_outlined,
            color: darkColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmar pedido',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _pasoDescripcion,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFB7BAC1),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    ),
  );

  String get _pasoDescripcion => switch (_paso) {
    0 => 'Revisa variantes, presentaciones, cantidades y precios.',
    1 => 'Selecciona un cliente o registra sus datos de entrega.',
    _ => 'Comprueba toda la información antes de guardar.',
  };

  Widget _stepper() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStepChip('Productos', 0),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          _buildStepChip('Cliente', 1),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          _buildStepChip('Confirmación', 2),
        ],
      ),
    ),
  );

  Widget _buildStepChip(String label, int stepIndex) {
    final isActive = _paso == stepIndex;
    final isCompleted = stepIndex < _paso;
    final color = isActive
        ? primaryColor
        : isCompleted
        ? const Color(0xFFD1FADF)
        : const Color(0xFFF2F4F7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? primaryColor
              : isCompleted
              ? const Color(0xFF6CE9A6)
              : const Color(0xFFE1E5EA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? darkColor : Colors.white,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF067647),
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : darkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
              color: darkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
    color: const Color(0xFFFFEBEE),
    child: Text(value, style: GoogleFonts.inter(color: Colors.red.shade700)),
  );

  Widget _buildPasoProductos(PedidosState state) {
    if (state.carrito.isEmpty) {
      return Center(
        child: Text(
          'No hay productos en el carrito',
          style: GoogleFonts.inter(fontSize: 16),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${state.lineasCarrito} productos · '
          '${state.cantidadPresentaciones} presentaciones',
          style: GoogleFonts.inter(
            color: darkColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...state.carrito.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final selectedOption = item.opcionSeleccionada;
          final step = selectedOption?.incremento ?? 1;
          final minimum = selectedOption?.pedidoMinimo ?? 1;
          return Container(
            key: ValueKey('carrito_linea_${item.claveCarrito}'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E5EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _itemImage(item),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: darkColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.varianteEtiqueta,
                            style: GoogleFonts.inter(
                              color: darkColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              if (item.varianteSku.isNotEmpty)
                                'SKU ${item.varianteSku}',
                              if (item.precioListaNombre.isNotEmpty)
                                'Lista ${item.precioListaNombre}',
                            ].join(' · '),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF667085),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminarItem(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFB42318),
                      ),
                    ),
                  ],
                ),
                if (item.atributosVariante.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.atributosVariante.entries
                        .map(
                          (attribute) => Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFF7F8FA),
                            side: const BorderSide(color: Color(0xFFE1E5EA)),
                            label: Text(
                              '${attribute.key}: ${attribute.value}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                if (item.opciones.length > 1)
                  DropdownButtonFormField<String>(
                    initialValue: item.presentacionId.isNotEmpty
                        ? item.presentacionId
                        : item.presentacion,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Presentación',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: item.opciones
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.id.isEmpty
                                ? option.nombre
                                : option.id,
                            child: Text(
                              '${option.nombre} · ${option.equivalencia}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<PedidosBloc>().add(
                        PedidoItemPresentacionCambiada(index, value),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DD),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '${item.presentacion} · ${item.equivalencia}',
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: item.cantidad > minimum
                          ? () => _actualizarCantidad(
                              index,
                              (item.cantidad - step).clamp(minimum, 999999),
                            )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '${item.cantidad}',
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _actualizarCantidad(index, item.cantidad + step),
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.precioUnitario == null
                              ? 'Por cotizar'
                              : 'S/ ${item.precioUnitario!.toStringAsFixed(2)} c/u',
                          style: GoogleFonts.inter(
                            color: item.precioUnitario == null
                                ? const Color(0xFFB54708)
                                : darkColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.subtotal == null
                              ? 'Total pendiente'
                              : 'S/ ${item.subtotal!.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: darkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        _resumenProductos(state),
      ],
    );
  }

  Widget _buildPasoCliente(PedidosState state) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClienteSelector(
          clienteSeleccionadoId: state.cliente?.id,
          onClienteSeleccionado: (cliente) {
            _clienteFormKey.currentState?.limpiar();
            context.read<PedidosBloc>().add(
              PedidoClienteSeleccionado(_clienteExistenteToPedido(cliente)),
            );
            setState(() => _paso = 2);
          },
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: Text(
                'Registrar cliente nuevo',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            if (state.cliente != null)
              TextButton.icon(
                onPressed: () {
                  context.read<PedidosBloc>().add(
                    const PedidoClienteLimpiado(),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Usar formulario'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClienteFormulario(
          key: _clienteFormKey,
          padding: EdgeInsets.zero,
          mostrarAuditoria: false,
          onChanged: (_) {
            final formularioTieneDatos =
                _clienteFormKey.currentState?.tieneDatos ?? false;
            if (formularioTieneDatos && state.cliente != null) {
              context.read<PedidosBloc>().add(const PedidoClienteLimpiado());
            }
            setState(() {});
          },
        ),
      ],
    ),
  );

  Widget _buildPasoConfirmacion(PedidosState state) {
    final cliente = state.cliente;
    if (cliente == null) {
      return const Center(child: Text('Complete los datos del cliente'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('CLIENTE'),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFEDEDED)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombre,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  Text('Teléfono: ${cliente.telefono}'),
                  if (cliente.ruc.isNotEmpty) Text('RUC: ${cliente.ruc}'),
                  if (cliente.dni.isNotEmpty) Text('DNI: ${cliente.dni}'),
                  Text('Dirección: ${cliente.direccion}'),
                  if (cliente.referencia.isNotEmpty)
                    Text('Referencia: ${cliente.referencia}'),
                  TextButton.icon(
                    onPressed: () => setState(() => _paso = 1),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar cliente'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _title('PRODUCTOS Y VARIANTES'),
          ...state.carrito.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5EA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.inventory_2_outlined, color: primaryColor),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          item.varianteEtiqueta,
                          style: GoogleFonts.inter(
                            color: darkColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.cantidad} × ${item.presentacion} · '
                          '${item.equivalencia}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF667085),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.subtotal == null
                        ? 'Por cotizar'
                        : 'S/ ${item.subtotal!.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: item.subtotal == null
                          ? const Color(0xFFB54708)
                          : darkColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _title('RESUMEN'),
          _resumenProductos(state),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _resumenRow(
                  'Hoja activa:',
                  state.hojaActiva?.codigo ?? 'No disponible',
                ),
                _resumenRow('Estado inicial:', 'Pendiente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _acciones(PedidosState state) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
    child: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final back = OutlinedButton(
            onPressed: state.guardando
                ? null
                : () {
                    if (_paso == 0) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _paso--);
                    }
                  },
            style: OutlinedButton.styleFrom(foregroundColor: darkColor),
            child: FittedBox(
              child: Text(_paso == 0 ? 'Seguir comprando' : 'Volver'),
            ),
          );
          final next = ElevatedButton(
            key: Key(_paso == 2 ? 'confirmar_pedido' : 'continuar_pedido'),
            onPressed: state.guardando || !_puedeContinuar(state)
                ? null
                : () => _continuar(state),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: state.guardando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FittedBox(
                    child: Text(
                      _paso == 0
                          ? 'Continuar'
                          : _paso == 1
                          ? 'Revisar pedido'
                          : 'Confirmar pedido',
                    ),
                  ),
          );
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [next, const SizedBox(height: 8), back],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [back, const SizedBox(width: 12), next],
          );
        },
      ),
    ),
  );

  bool _puedeContinuar(PedidosState state) {
    if (_paso == 0) {
      return state.carrito.isNotEmpty &&
          state.carrito.every((item) => item.cantidad > 0);
    }
    if (_paso == 1) {
      return state.cliente != null ||
          (_clienteFormKey.currentState?.tieneDatosMinimos ?? false);
    }
    return state.cliente != null;
  }

  void _continuar(PedidosState state) {
    if (_paso == 0) {
      setState(() => _paso = 1);
      return;
    }
    if (_paso == 1) {
      final formulario = _clienteFormKey.currentState;
      if (formulario != null && formulario.tieneDatos) {
        if (!formulario.validate()) return;
        context.read<PedidosBloc>().add(
          PedidoClienteSeleccionado(
            _nuevoClienteToPedido(formulario.toNuevoCliente()),
          ),
        );
        setState(() => _paso = 2);
        return;
      }
      if (state.cliente == null) {
        _mensaje('Selecciona o registra un cliente para continuar.');
        return;
      }
      setState(() => _paso = 2);
      return;
    }
    context.read<PedidosBloc>().add(const PedidoConfirmado());
  }

  ClientePedido _clienteExistenteToPedido(clientes_domain.Cliente cliente) =>
      ClientePedido(
        id: cliente.id,
        nombre: cliente.nombre,
        telefono: cliente.telefono,
        dni: cliente.dni ?? '',
        ruc: cliente.ruc ?? '',
        tipoEntrega: 'entrega',
        direccion: cliente.direccion ?? '',
        referencia: cliente.referencia ?? '',
        fotoUbicacionPath: cliente.fotoUbicacionPath,
        observaciones: cliente.observaciones ?? '',
      );

  ClientePedido _nuevoClienteToPedido(NuevoCliente cliente) => ClientePedido(
    nombre: cliente.nombre,
    telefono: cliente.telefono,
    dni: cliente.dni,
    ruc: cliente.ruc,
    tipoEntrega: 'entrega',
    direccion: cliente.direccion,
    referencia: cliente.referencia,
    fotoUbicacionPath: cliente.fotoUbicacionPath,
    observaciones: cliente.observaciones,
  );

  void _actualizarCantidad(int index, int nuevaCantidad) {
    context.read<PedidosBloc>().add(
      PedidoItemCantidadCambiada(index, nuevaCantidad),
    );
  }

  void _eliminarItem(int index) {
    context.read<PedidosBloc>().add(PedidoItemEliminado(index));
    if (context.read<PedidosBloc>().state.carrito.length <= 1 && _paso > 0) {
      setState(() => _paso = 0);
    }
  }

  Widget _itemImage(PedidoItem item) {
    if (item.imagenPath == null) {
      return const Icon(Icons.image, color: Colors.grey);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(item.imagenPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  Widget _resumenProductos(PedidosState state) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E5EA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resumenRow('Productos:', '${state.lineasCarrito}'),
        _resumenRow(
          'Presentaciones solicitadas:',
          '${state.cantidadPresentaciones}',
        ),
        if (state.totalParcial) ...[
          _resumenRow('Líneas por cotizar:', '${state.lineasSinPrecio}'),
          _resumenRow('Total final:', 'Pendiente de valorización'),
          if (state.subtotalConocido > 0)
            _resumenRow(
              'Importe conocido:',
              'S/ ${state.subtotalConocido.toStringAsFixed(2)}',
            ),
        ] else
          _resumenRow(
            'Total:',
            'S/ ${state.subtotalConocido.toStringAsFixed(2)}',
          ),
      ],
    ),
  );

  Widget _title(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      value,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: Colors.grey.shade600,
      ),
    ),
  );

  Widget _resumenRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  void _mensaje(String value) {
    AppNotice.info(context, value);
  }
}
