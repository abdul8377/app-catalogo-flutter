import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido.dart';
import '../bloc/pedidos_bloc.dart';
import '../bloc/pedidos_event.dart';
import '../bloc/pedidos_state.dart';

class ConfirmarPedidoDialog extends StatefulWidget {
  const ConfirmarPedidoDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) => BlocProvider<PedidosBloc>.value(
          value: context.read<PedidosBloc>(),
          child: const ConfirmarPedidoDialog(),
        ),
      ) ??
      false;

  @override
  State<ConfirmarPedidoDialog> createState() => _ConfirmarPedidoDialogState();
}

class _ConfirmarPedidoDialogState extends State<ConfirmarPedidoDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  int _paso = 0;

  final _searchCtrl = TextEditingController();
  final nombre = TextEditingController();
  final telefono = TextEditingController();
  final dni = TextEditingController();
  final ruc = TextEditingController();
  final direccion = TextEditingController();
  final referencia = TextEditingController();
  final observaciones = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    nombre.dispose();
    telefono.dispose();
    dni.dispose();
    ruc.dispose();
    direccion.dispose();
    referencia.dispose();
    observaciones.dispose();
    super.dispose();
  }

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
          final width = (constraints.maxWidth * .85).clamp(320.0, 980.0);
          final height = constraints.maxHeight * .9;
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
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Confirmar pedido',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: darkColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          style: IconButton.styleFrom(foregroundColor: Colors.grey),
        ),
      ],
    ),
  );

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withValues(alpha: .2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? primaryColor : Colors.transparent),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _error(String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
    color: const Color(0xFFFFEBEE),
    child: Text(
      value,
      style: GoogleFonts.inter(color: const Color(0xFFC62828)),
    ),
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
        ...state.carrito.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final tienePrecio = item.precioUnitario != null;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEDEDED)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: item.imagenPath == null
                              ? const Color(0xFFEEEEEE)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${item.equivalencia} • ${item.presentacion}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (tienePrecio) ...[
                              Text(
                                'S/ ${item.precioUnitario!.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Total: S/ ${item.subtotal!.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ] else
                              Text(
                                'Sin precio',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cantidad = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: item.cantidad > 1
                                ? () => _actualizarCantidad(
                                    index,
                                    item.cantidad - 1,
                                  )
                                : null,
                          ),
                          Text(
                            '${item.cantidad}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _actualizarCantidad(index, item.cantidad + 1),
                          ),
                        ],
                      );
                      final eliminar = TextButton.icon(
                        onPressed: () => _eliminarItem(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      );
                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: cantidad,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: eliminar,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [cantidad, const Spacer(), eliminar],
                      );
                    },
                  ),
                ],
              ),
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
        Text(
          'Cliente',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, DNI, RUC o teléfono',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) =>
              context.read<PedidosBloc>().add(PedidoClienteBuscado(value)),
        ),
        const SizedBox(height: 12),
        if (state.clientes.isNotEmpty)
          ...state.clientes.map(
            (cliente) => Material(
              color: Colors.transparent,
              child: ListTile(
                selected: state.cliente == cliente,
                selectedTileColor: primaryColor.withValues(alpha: .12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(cliente.nombre),
                subtitle: Text(cliente.telefono),
                trailing: state.cliente == cliente
                    ? const Icon(Icons.check_circle, color: Color(0xFFFFC500))
                    : null,
                onTap: () {
                  context.read<PedidosBloc>().add(
                    PedidoClienteSeleccionado(cliente),
                  );
                  setState(() => _paso = 2);
                },
              ),
            ),
          )
        else
          Text(
            'No se encontraron clientes.',
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          ),
        const Divider(height: 28),
        _field(nombre, 'Nombre o razón social *'),
        _field(telefono, 'Teléfono *', keyboardType: TextInputType.phone),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              _field(dni, 'DNI', keyboardType: TextInputType.number),
              _field(ruc, 'RUC', keyboardType: TextInputType.number),
            ];
            if (constraints.maxWidth < 520) return Column(children: fields);
            return Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 10),
                Expanded(child: fields[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 5),
        _field(direccion, 'Dirección *'),
        _field(referencia, 'Referencia'),
        _field(observaciones, 'Observaciones', maxLines: 2),
      ],
    ),
  );

  Widget _buildPasoConfirmacion(PedidosState state) {
    final cliente = state.cliente;
    if (cliente == null) {
      return Center(child: Text('Complete los datos del cliente'));
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
          _title('PRODUCTOS'),
          ...state.carrito.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEDEDED)),
              ),
              child: ListTile(
                title: Text('${item.nombre} - ${item.equivalencia}'),
                subtitle: Text('${item.cantidad} ${item.presentacion}'),
                trailing: Text(
                  item.subtotal == null
                      ? 'Sin precio'
                      : 'S/ ${item.subtotal!.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _title('RESUMEN'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _resumenRow(
                  'Subtotal conocido:',
                  'S/ ${state.subtotalConocido.toStringAsFixed(2)}',
                ),
                if (state.productosSinPrecio > 0)
                  _resumenRow(
                    'Productos sin precio:',
                    '${state.productosSinPrecio}',
                  ),
                _resumenRow(
                  'Total final:',
                  state.productosSinPrecio > 0
                      ? 'Pendiente de valorización'
                      : 'S/ ${state.subtotalConocido.toStringAsFixed(2)}',
                ),
                const Divider(),
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
          (nombre.text.trim().isNotEmpty && telefono.text.trim().isNotEmpty);
    }
    return state.cliente != null;
  }

  void _continuar(PedidosState state) {
    if (_paso == 0) {
      setState(() => _paso = 1);
      return;
    }
    if (_paso == 1) {
      if (nombre.text.trim().isNotEmpty || telefono.text.trim().isNotEmpty) {
        final client = ClientePedido(
          nombre: nombre.text.trim(),
          telefono: telefono.text.trim(),
          dni: dni.text.trim(),
          ruc: ruc.text.trim(),
          tipoEntrega: 'entrega',
          direccion: direccion.text.trim(),
          referencia: referencia.text.trim(),
          observaciones: observaciones.text.trim(),
        );
        if (!_validarCliente(client)) return;
        context.read<PedidosBloc>().add(PedidoClienteSeleccionado(client));
      } else if (state.cliente == null) {
        _mensaje('Selecciona o registra un cliente para continuar.');
        return;
      }
      setState(() => _paso = 2);
      return;
    }
    context.read<PedidosBloc>().add(const PedidoConfirmado());
  }

  bool _validarCliente(ClientePedido cliente) {
    if (cliente.nombre.isEmpty || cliente.telefono.isEmpty) {
      _mensaje('Completa el nombre y teléfono del cliente.');
      return false;
    }
    final digits = cliente.telefono.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      _mensaje('Ingresa un teléfono válido.');
      return false;
    }
    if (cliente.direccion.isEmpty) {
      _mensaje('Ingresa la dirección del cliente.');
      return false;
    }
    return true;
  }

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
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resumenRow('Productos:', '${state.carrito.length}'),
        Text(
          'Subtotal conocido: S/ ${state.subtotalConocido.toStringAsFixed(2)}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        if (state.productosSinPrecio > 0)
          _resumenRow('Productos sin precio:', '${state.productosSinPrecio}'),
        _resumenRow(
          'Total final:',
          state.totalParcial
              ? 'Pendiente de valorización'
              : 'S/ ${state.subtotalConocido.toStringAsFixed(2)}',
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => setState(() {}),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }
}
