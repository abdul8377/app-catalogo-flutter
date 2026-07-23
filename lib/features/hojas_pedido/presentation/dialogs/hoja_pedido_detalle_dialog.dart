import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';
import '../../domain/repositories/hojas_pedido_repository.dart';
import '../bloc/hoja_detalle_bloc.dart';
import '../widgets/hoja_detalle_clientes.dart';
import '../widgets/hoja_detalle_pedidos.dart';
import '../widgets/hoja_detalle_productos.dart';
import '../widgets/hoja_detalle_resumen.dart';
import '../widgets/hoja_estado_badge.dart';
import '../widgets/hoja_historial_timeline.dart';

class HojaPedidoDetalleDialog extends StatelessWidget {
  const HojaPedidoDetalleDialog({
    required this.hojaId,
    required this.onVerPedidos,
    required this.onGestionOperativa,
    required this.onCompletar,
    super.key,
  });

  final String hojaId;
  final VoidCallback onVerPedidos;
  final VoidCallback onGestionOperativa;
  final ValueChanged<HojaPedido> onCompletar;

  static Future<void> show(
    BuildContext context, {
    required HojaPedido hoja,
    required VoidCallback onVerPedidos,
    required VoidCallback onGestionOperativa,
    required ValueChanged<HojaPedido> onCompletar,
  }) {
    final repository = context.read<HojasPedidoRepository>();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => BlocProvider(
        create: (_) =>
            HojaDetalleBloc(repository)..add(HojaDetalleStarted(hoja.id)),
        child: HojaPedidoDetalleDialog(
          hojaId: hoja.id,
          onVerPedidos: onVerPedidos,
          onGestionOperativa: onGestionOperativa,
          onCompletar: onCompletar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: BlocBuilder<HojaDetalleBloc, HojaDetalleState>(
      builder: (context, state) {
        if (state.loading) {
          return const SizedBox(
            width: 220,
            height: 180,
            child: Card(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC500)),
              ),
            ),
          );
        }
        if (state.hoja == null) {
          return SizedBox(
            width: 420,
            child: AlertDialog(
              title: const Text('No se pudo abrir la hoja'),
              content: Text(state.error ?? 'La hoja ya no está disponible.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        }
        return _DetalleContent(
          hoja: state.hoja!,
          onVerPedidos: onVerPedidos,
          onGestionOperativa: onGestionOperativa,
          onCompletar: onCompletar,
        );
      },
    ),
  );
}

class _DetalleContent extends StatefulWidget {
  const _DetalleContent({
    required this.hoja,
    required this.onVerPedidos,
    required this.onGestionOperativa,
    required this.onCompletar,
  });

  final HojaPedido hoja;
  final VoidCallback onVerPedidos;
  final VoidCallback onGestionOperativa;
  final ValueChanged<HojaPedido> onCompletar;

  @override
  State<_DetalleContent> createState() => _DetalleContentState();
}

class _DetalleContentState extends State<_DetalleContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hoja = widget.hoja;
      return Container(
        width: constraints.maxWidth * 0.9,
        height: constraints.maxHeight * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
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
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              hoja.codigo,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            HojaEstadoBadge(estado: hoja.estado),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 22),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey,
                          backgroundColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${hoja.vendedor} • Iniciada el ${DateFormat('dd/MM/yyyy').format(hoja.fechaApertura)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Pedidos'),
                Tab(text: 'Productos'),
                Tab(text: 'Clientes'),
                Tab(text: 'Historial'),
              ],
              labelColor: const Color(0xFF1F1F1F),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFFC500),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  HojaDetalleResumen(hoja: hoja),
                  HojaDetallePedidos(
                    hoja: hoja,
                    onVerPedido: (_) =>
                        _abrirYSalir(context, widget.onVerPedidos),
                  ),
                  HojaDetalleProductos(
                    hoja: hoja,
                    onGestionOperativa: () =>
                        _abrirYSalir(context, widget.onGestionOperativa),
                  ),
                  HojaDetalleClientes(
                    hoja: hoja,
                    onVerPedidos: () =>
                        _abrirYSalir(context, widget.onVerPedidos),
                  ),
                  HojaHistorialTimeline(entradas: hoja.historial),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _abrirYSalir(context, widget.onGestionOperativa),
                    child: const Text('Ver gestión operativa'),
                  ),
                  if (hoja.abierta)
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCompletar(hoja);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC500),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Completar hoja'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  void _abrirYSalir(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }
}
