import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/pedidos_repository.dart';
import '../bloc/pedidos_listado_bloc.dart';
import '../bloc/pedidos_listado_event.dart';
import '../bloc/pedidos_listado_state.dart';
import '../bloc/productos_consolidados_bloc.dart';
import '../bloc/productos_consolidados_event.dart';
import '../views/pedidos_listado_view.dart';
import '../views/preparacion_carga_view.dart';
import '../views/productos_consolidados_view.dart';
import '../widgets/pedidos_header.dart';

class PedidosPage extends StatelessWidget {
  const PedidosPage({
    this.initialTab = 0,
    this.initialHojaCodigo,
    this.onOpenCliente,
    this.onOpenHoja,
    super.key,
  });

  final int initialTab;
  final String? initialHojaCodigo;
  final ValueChanged<String>? onOpenCliente;
  final ValueChanged<String>? onOpenHoja;

  @override
  Widget build(BuildContext context) {
    final bloc = PedidosListadoBloc(context.read<PedidosRepository>())
      ..add(const PedidosListadoStarted());
    if (initialHojaCodigo != null) {
      bloc.add(
        PedidosListadoFiltrosAvanzadosAplicados(hoja: initialHojaCodigo),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => bloc),
        BlocProvider(
          create: (context) => ProductosConsolidadosBloc(
            context.read<PedidosRepository>(),
            initialHojaCodigo: initialHojaCodigo,
          )..add(const ProductosConsolidadosStarted()),
        ),
      ],
      child: _PedidosPageView(
        initialTab: initialTab,
        hojaCodigo: initialHojaCodigo,
        onOpenCliente: onOpenCliente,
        onOpenHoja: onOpenHoja,
      ),
    );
  }
}

class _PedidosPageView extends StatefulWidget {
  const _PedidosPageView({
    required this.initialTab,
    this.hojaCodigo,
    this.onOpenCliente,
    this.onOpenHoja,
  });

  final int initialTab;
  final String? hojaCodigo;
  final ValueChanged<String>? onOpenCliente;
  final ValueChanged<String>? onOpenHoja;

  @override
  State<_PedidosPageView> createState() => _PedidosPageViewState();
}

class _PedidosPageViewState extends State<_PedidosPageView> {
  late int _currentTab;
  int _preparacionRevision = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(204),
      child: BlocBuilder<PedidosListadoBloc, PedidosListadoState>(
        builder: (context, state) => PedidosHeader(
          currentTab: _currentTab,
          totalPedidos: state.pedidosFiltrados.length,
          onRefresh: _actualizar,
          onTabChanged: _cambiarTab,
        ),
      ),
    ),
    body: IndexedStack(
      index: _currentTab,
      children: [
        PedidosListadoView(
          vistaLista: true,
          onOpenCliente: widget.onOpenCliente,
          onOpenHoja: widget.onOpenHoja,
        ),
        ProductosConsolidadosView(initialHojaCodigo: widget.hojaCodigo),
        PreparacionCargaView(
          key: ValueKey('preparacion-$_preparacionRevision'),
        ),
      ],
    ),
  );

  void _actualizar() {
    if (_currentTab == 1) {
      context.read<ProductosConsolidadosBloc>().add(
        const ProductosConsolidadosRecargados(),
      );
      return;
    }
    if (_currentTab == 2) {
      setState(() => _preparacionRevision++);
      return;
    }
    context.read<PedidosListadoBloc>().add(const PedidosListadoRecargado());
  }

  void _cambiarTab(int value) {
    setState(() {
      _currentTab = value;
      if (value == 2) _preparacionRevision++;
    });
    if (value == 1) {
      context.read<ProductosConsolidadosBloc>().add(
        const ProductosConsolidadosRecargados(),
      );
    } else if (value == 0) {
      context.read<PedidosListadoBloc>().add(const PedidosListadoRecargado());
    }
  }
}
