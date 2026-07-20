import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/repositories/clientes_repository.dart';
import '../bloc/clientes_bloc.dart';
import '../bloc/clientes_event.dart';
import '../bloc/clientes_state.dart';
import '../widgets/cliente_card.dart';
import '../widgets/cliente_detalle_dialog.dart';
import '../widgets/clientes_empty_state.dart';
import '../widgets/clientes_filtros.dart';
import 'cliente_form_page.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ClientesBloc(context.read<ClientesRepository>())
          ..add(const ClientesStarted()),
    child: const _ClientesView(),
  );
}

class _ClientesView extends StatelessWidget {
  const _ClientesView();

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ClientesBloc, ClientesState>(
    listenWhen: (previous, current) =>
        previous.error != current.error && current.error != null,
    listener: (context, state) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.error!))),
    builder: (context, state) {
      final clientes = state.clientesFiltrados;
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clientes',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                '${clientes.length} clientes registrados',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: darkColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (state.actualizando)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Actualizar clientes',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => context.read<ClientesBloc>().add(
                  const ClientesRecargados(),
                ),
              ),
            IconButton(
              tooltip: state.vistaGrilla ? 'Ver como lista' : 'Ver como grilla',
              icon: Icon(
                state.vistaGrilla ? Icons.view_list : Icons.grid_view,
                color: primaryColor,
              ),
              onPressed: () => context.read<ClientesBloc>().add(
                ClientesVistaCambiada(!state.vistaGrilla),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            ClientesFiltros(
              busqueda: state.busqueda,
              filtrosRapidos: state.filtrosRapidos,
              ordenSeleccionado: state.orden,
              onBusquedaCambiada: (value) => context.read<ClientesBloc>().add(
                ClientesBusquedaCambiada(value),
              ),
              onFiltroRapido: (value) => context.read<ClientesBloc>().add(
                ClientesFiltroRapidoCambiado(value),
              ),
              onFiltrosAplicados: (orden) => context.read<ClientesBloc>().add(
                ClientesFiltrosAvanzadosAplicados(orden: orden),
              ),
              onOrdenCambiado: (value) => context.read<ClientesBloc>().add(
                ClientesOrdenCambiado(value),
              ),
            ),
            Expanded(child: _contenido(context, state, clientes)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(context),
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 4,
          icon: const Icon(Icons.add, size: 22),
          label: Text(
            'Nuevo cliente',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      );
    },
  );

  Widget _contenido(
    BuildContext context,
    ClientesState state,
    List<Cliente> clientes,
  ) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (clientes.isEmpty) {
      return ClientesEmptyState(
        onLimpiarFiltros: () =>
            context.read<ClientesBloc>().add(const ClientesFiltrosLimpiados()),
      );
    }
    if (!state.vistaGrilla) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: clientes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => SizedBox(
          height: 290,
          child: _clienteCard(context, clientes[index]),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: constraints.maxWidth < 520 ? 520 : 370,
          mainAxisExtent: 310,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: clientes.length,
        itemBuilder: (_, index) => _clienteCard(context, clientes[index]),
      ),
    );
  }

  Widget _clienteCard(BuildContext context, Cliente cliente) => ClienteCard(
    cliente: cliente,
    onVer: () => ClienteDetalleDialog.show(
      context,
      clienteId: cliente.id,
      onEditar: () => _abrirFormulario(context, clienteId: cliente.id),
      onNuevoPedido: () => _nuevoPedidoPendiente(context, cliente),
    ),
    onEditar: () => _abrirFormulario(context, clienteId: cliente.id),
    onNuevoPedido: () => _nuevoPedidoPendiente(context, cliente),
    onActivarDesactivar: () => _confirmarEstado(context, cliente),
  );

  Future<void> _abrirFormulario(
    BuildContext context, {
    String? clienteId,
  }) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider<ClientesRepository>.value(
          value: context.read<ClientesRepository>(),
          child: ClienteFormPage(clienteId: clienteId),
        ),
      ),
    );
    if (guardado == true && context.mounted) {
      context.read<ClientesBloc>().add(const ClientesRecargados());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              clienteId == null
                  ? 'Cliente registrado correctamente.'
                  : 'Cliente actualizado correctamente.',
            ),
          ),
        );
    }
  }

  Future<void> _confirmarEstado(BuildContext context, Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cliente.activo ? 'Desactivar cliente' : 'Activar cliente'),
        content: Text(
          cliente.activo
              ? 'El cliente dejará de aparecer como activo, pero conservará su historial.'
              : 'El cliente volverá a estar disponible como activo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: cliente.activo
                  ? const Color(0xFFC62828)
                  : const Color(0xFF2E7D32),
            ),
            child: Text(cliente.activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      context.read<ClientesBloc>().add(ClienteEstadoCambiado(cliente.id));
    }
  }

  void _nuevoPedidoPendiente(BuildContext context, Cliente cliente) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Nuevo pedido para ${cliente.nombre} quedará conectado al flujo de pedidos.',
          ),
        ),
      );
  }
}
