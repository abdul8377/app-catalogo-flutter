import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_pedido_resumen.dart';
import '../../domain/repositories/clientes_repository.dart';

class ClienteDetalleDialog extends StatefulWidget {
  const ClienteDetalleDialog({
    required this.clienteId,
    this.onEditar,
    this.onNuevoPedido,
    super.key,
  });

  final String clienteId;
  final VoidCallback? onEditar;
  final VoidCallback? onNuevoPedido;

  static Future<void> show(
    BuildContext context, {
    required String clienteId,
    VoidCallback? onEditar,
    VoidCallback? onNuevoPedido,
  }) {
    final repository = context.read<ClientesRepository>();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => RepositoryProvider<ClientesRepository>.value(
        value: repository,
        child: ClienteDetalleDialog(
          clienteId: clienteId,
          onEditar: onEditar,
          onNuevoPedido: onNuevoPedido,
        ),
      ),
    );
  }

  @override
  State<ClienteDetalleDialog> createState() => _ClienteDetalleDialogState();
}

class _ClienteDetalleDialogState extends State<ClienteDetalleDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Cliente? _cliente;
  List<ClientePedidoResumen> _pedidos = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _cliente == null && _error == null) _cargarDetalle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    try {
      final repository = context.read<ClientesRepository>();
      final results = await Future.wait([
        repository.obtenerCliente(widget.clienteId),
        repository.obtenerPedidosCliente(widget.clienteId),
      ]);
      if (!mounted) return;
      final cliente = results[0] as Cliente?;
      if (cliente == null) {
        setState(() {
          _loading = false;
          _error = 'No se encontró el cliente.';
        });
        return;
      }
      setState(() {
        _loading = false;
        _cliente = cliente;
        _pedidos = results[1] as List<ClientePedidoResumen>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el detalle del cliente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFC500);
    const darkColor = Color(0xFF1F1F1F);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 480
              ? constraints.maxWidth
              : (constraints.maxWidth * .8).clamp(420.0, 900.0);
          final height = constraints.maxHeight * .85;
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _errorView(context, _error!)
                : _detalle(_cliente!, primaryColor, darkColor),
          );
        },
      ),
    );
  }

  Widget _detalle(Cliente cliente, Color primaryColor, Color darkColor) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cliente.activo
                        ? primaryColor.withValues(alpha: .2)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      cliente.iniciales,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.tipo,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                  splashRadius: 20,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey,
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Ubicación'),
                Tab(text: 'Pedidos'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabResumen(cliente, darkColor),
                _buildTabUbicacion(cliente, primaryColor),
                _buildTabPedidos(_pedidos, primaryColor, darkColor),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
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
                  final buttons = [
                    OutlinedButton.icon(
                      onPressed: widget.onEditar == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onEditar?.call();
                            },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar cliente'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkColor,
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onNuevoPedido == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onNuevoPedido?.call();
                            },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Nuevo pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ];
                  if (constraints.maxWidth < 620) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 8),
                        buttons[1],
                        const SizedBox(height: 8),
                        buttons[2],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 12),
                      Expanded(child: buttons[1]),
                      const SizedBox(width: 12),
                      Expanded(child: buttons[2]),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildTabResumen(
    Cliente cliente,
    Color darkColor,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeccionTitulo('Información general'),
        const SizedBox(height: 16),
        _buildFilaDato('Nombre', cliente.nombre),
        _buildFilaDato('Tipo', cliente.tipo),
        _buildFilaDato(
          'Estado',
          cliente.activo ? 'Activo' : 'Inactivo',
          valorColor: cliente.activo ? Colors.green : Colors.red,
        ),
        const Divider(height: 24),
        _buildSeccionTitulo('Contacto'),
        const SizedBox(height: 16),
        _buildFilaDato('Teléfono', cliente.telefono),
        if ((cliente.dni ?? '').isNotEmpty) _buildFilaDato('DNI', cliente.dni!),
        if ((cliente.ruc ?? '').isNotEmpty) _buildFilaDato('RUC', cliente.ruc!),
        const Divider(height: 24),
        _buildSeccionTitulo('Entrega y ubicación'),
        const SizedBox(height: 16),
        _buildFilaDato('Dirección', _texto(cliente.direccion)),
        _buildFilaDato('Referencia', _texto(cliente.referencia)),
        const Divider(height: 24),
        _buildSeccionTitulo('Información adicional'),
        const SizedBox(height: 16),
        _buildFilaDato('Registrado', _formatDate(cliente.fechaRegistro)),
        _buildFilaDato('Pedidos', '${cliente.pedidosCount}'),
        if (cliente.ultimoPedido != null)
          _buildFilaDato('Último pedido', _formatDate(cliente.ultimoPedido!)),
        if ((cliente.observaciones ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Observaciones',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cliente.observaciones!,
            style: GoogleFonts.inter(fontSize: 14, color: darkColor),
          ),
        ],
      ],
    ),
  );

  Widget _buildTabUbicacion(Cliente cliente, Color primaryColor) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeccionTitulo('Dirección'),
            const SizedBox(height: 12),
            _infoBox(
              icon: Icons.location_on_outlined,
              color: primaryColor,
              text: _texto(cliente.direccion),
            ),
            const SizedBox(height: 20),
            _buildSeccionTitulo('Referencia'),
            const SizedBox(height: 12),
            _infoBox(
              icon: Icons.info_outline,
              color: primaryColor,
              text: _texto(cliente.referencia),
            ),
            const SizedBox(height: 20),
            _buildSeccionTitulo('Fotografía de ubicación'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _mostrarFoto(cliente.fotoUbicacionPath),
              child: Container(
                key: const Key('cliente_detalle_foto'),
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: _fotoUbicacion(cliente.fotoUbicacionPath),
              ),
            ),
          ],
        ),
      );

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String text,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _fotoUbicacion(String? path) {
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Sin foto de ubicación',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildTabPedidos(
    List<ClientePedidoResumen> pedidos,
    Color primaryColor,
    Color darkColor,
  ) {
    if (pedidos.isEmpty) {
      return Center(
        child: Text(
          'No hay pedidos recientes',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pedido.codigo,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _colorEstadoPedido(
                          pedido.estado,
                        ).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pedido.estado,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorEstadoPedido(pedido.estado),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(pedido.fecha),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pedido.cantidadProductos} productos • ${pedido.totalParcial ? 'Total parcial' : 'S/ ${pedido.total.toStringAsFixed(2)}'}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorView(BuildContext context, String error) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  void _mostrarFoto(String? path) {
    if (path == null || path.isEmpty || !File(path).existsSync()) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Color _colorEstadoPedido(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'completado':
      case 'confirmado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSeccionTitulo(String titulo) => Row(
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
        titulo,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: const Color(0xFF1F1F1F),
        ),
      ),
    ],
  );

  Widget _buildFilaDato(String label, String valor, {Color? valorColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
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
                valor,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: valorColor ?? const Color(0xFF1F1F1F),
                ),
              ),
            ),
          ],
        ),
      );

  String _texto(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'No especificada' : text;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
