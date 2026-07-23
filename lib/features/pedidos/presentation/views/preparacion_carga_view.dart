import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../bloc/preparacion_carga_bloc.dart';
import '../bloc/preparacion_carga_event.dart';
import '../bloc/preparacion_carga_state.dart';
import '../dialogs/confirmar_carga_dialog.dart';
import '../dialogs/pedido_productos_cargados_dialog.dart';
import '../dialogs/registrar_preparacion_dialog.dart';
import '../widgets/estados_vacios.dart';
import '../widgets/preparacion_faltante_card.dart';
import '../widgets/preparacion_grupo_header.dart';
import '../widgets/preparacion_modo_chips.dart';
import '../widgets/preparacion_pedido_card.dart';

class PreparacionCargaView extends StatelessWidget {
  const PreparacionCargaView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        PreparacionCargaBloc(context.read<PedidosRepository>())
          ..add(const PreparacionCargaStarted()),
    child: const _PreparacionCargaContent(),
  );
}

class _PreparacionCargaContent extends StatelessWidget {
  const _PreparacionCargaContent();

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PreparacionCargaBloc, PreparacionCargaState>(
    listenWhen: (previous, current) =>
        previous.error != current.error || previous.message != current.message,
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
      if (state.loading) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC500)),
        );
      }
      if (state.sinHojaActiva) {
        return const EstadoVacioPedidos(
          icon: Icons.description_outlined,
          title: 'No existe una hoja de pedido activa',
          message:
              'Crea o selecciona una hoja activa para comenzar la preparación y carga de sus pedidos.',
        );
      }
      return Column(
        children: [
          _SubTabs(
            current: state.subTab,
            onChanged: (value) => context.read<PreparacionCargaBloc>().add(
              PreparacionCargaSubTabCambiada(value),
            ),
          ),
          PreparacionModoChips(
            selected: state.modoAgrupacion,
            onChanged: (modo) => context.read<PreparacionCargaBloc>().add(
              PreparacionCargaModoAgrupacionCambiado(modo),
            ),
          ),
          Expanded(child: _construirVistaAgrupada(context, state)),
        ],
      );
    },
  );

  Widget _construirVistaAgrupada(
    BuildContext context,
    PreparacionCargaState state,
  ) {
    final datos = state.pedidosFiltrados;

    if (datos.isEmpty) {
      return EstadoVacioPedidos(
        icon: state.subTab == 0
            ? Icons.inventory_2_outlined
            : Icons.local_shipping_outlined,
        title: state.subTab == 0
            ? 'No hay pedidos en preparación'
            : 'No hay pedidos para cargar',
        message: state.subTab == 0
            ? 'Cuando existan pedidos con productos aparecerán aquí para registrar la preparación física.'
            : 'Los pedidos aparecerán en carga cuando todos sus productos estén preparados.',
      );
    }

    switch (state.modoAgrupacion) {
      case PreparacionModoAgrupacion.estado:
        return _buildAgrupacionPorEstado(context, state);
      case PreparacionModoAgrupacion.empresa:
        return _buildAgrupacionPor(
          context,
          state,
          agruparPor: (pedido) => pedido.empresa,
        );
      case PreparacionModoAgrupacion.categoria:
        return _buildAgrupacionPor(
          context,
          state,
          agruparPor: (pedido) => pedido.categoria,
        );
      case PreparacionModoAgrupacion.almacen:
        return _buildAgrupacionPor(
          context,
          state,
          agruparPor: (pedido) => pedido.zonaAlmacen,
        );
      case PreparacionModoAgrupacion.cliente:
        return _buildAgrupacionPor(
          context,
          state,
          agruparPor: (pedido) => pedido.cliente,
        );
      case PreparacionModoAgrupacion.zonaEntrega:
        return _buildAgrupacionPor(
          context,
          state,
          agruparPor: (pedido) => pedido.zonaEntrega,
        );
      case PreparacionModoAgrupacion.faltantes:
        return _buildListaFaltantes(context, state);
    }
  }

  Widget _buildAgrupacionPorEstado(
    BuildContext context,
    PreparacionCargaState state,
  ) {
    final estados = state.subTab == 0
        ? const ['pendiente', 'en_preparacion', 'listo_cargar']
        : const ['listo_cargar', 'cargado'];
    final agrupados = <String, List<PedidoPreparacion>>{};

    for (final pedido in state.pedidosFiltrados) {
      agrupados.putIfAbsent(pedido.estadoPreparacion, () => []).add(pedido);
    }

    final grupos = estados
        .where((estado) => (agrupados[estado] ?? const []).isNotEmpty)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length,
      itemBuilder: (_, index) {
        final estado = grupos[index];
        final items = agrupados[estado] ?? const <PedidoPreparacion>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreparacionGrupoHeader(
              titulo: _formatearClave(estado),
              cantidad: items.length,
              color: _colorEstado(estado),
            ),
            ...items.map(
              (pedido) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _pedidoCard(context, state, pedido),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAgrupacionPor(
    BuildContext context,
    PreparacionCargaState state, {
    required String Function(PedidoPreparacion pedido) agruparPor,
  }) {
    final agrupados = <String, List<PedidoPreparacion>>{};

    for (final pedido in state.pedidosFiltrados) {
      final clave = agruparPor(pedido).trim();
      agrupados
          .putIfAbsent(clave.isEmpty ? 'Sin clasificar' : clave, () => [])
          .add(pedido);
    }

    final grupos = agrupados.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length,
      itemBuilder: (_, index) {
        final grupo = grupos[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreparacionGrupoHeader(
              titulo: grupo.key,
              cantidad: grupo.value.length,
            ),
            ...grupo.value.map(
              (pedido) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _pedidoCard(context, state, pedido),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildListaFaltantes(
    BuildContext context,
    PreparacionCargaState state,
  ) {
    final faltantes = <MapEntry<PedidoPreparacion, ProductoPreparacion>>[];

    for (final pedido in state.pedidosFiltrados) {
      for (final producto in pedido.productos) {
        if (!producto.completado) {
          faltantes.add(MapEntry(pedido, producto));
        }
      }
    }

    if (faltantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos pendientes',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faltantes.length,
      itemBuilder: (_, index) {
        final pedido = faltantes[index].key;
        final producto = faltantes[index].value;

        return PreparacionFaltanteCard(
          pedido: pedido,
          producto: producto,
          onTap: () => _registrarPreparacion(context, pedido),
        );
      },
    );
  }

  Widget _pedidoCard(
    BuildContext context,
    PreparacionCargaState state,
    PedidoPreparacion pedido,
  ) => PreparacionPedidoCard(
    pedido: pedido,
    onVerDetalle: pedido.cargado
        ? () => PedidoProductosCargadosDialog.show(context, pedido: pedido)
        : () => _registrarPreparacion(context, pedido),
    onCargar: state.subTab == 1 && pedido.listoParaCargar
        ? () => _confirmarCarga(context, pedido)
        : null,
  );

  String _formatearClave(String clave) {
    switch (clave) {
      case 'pendiente':
        return 'Pendiente de preparar';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo_cargar':
        return 'Listo para cargar';
      case 'cargado':
        return 'Cargado';
      default:
        return clave;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_preparacion':
        return Colors.blue;
      case 'listo_cargar':
        return Colors.teal;
      case 'cargado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _registrarPreparacion(
    BuildContext context,
    PedidoPreparacion pedido,
  ) async {
    final preparacion = await RegistrarPreparacionDialog.show(
      context,
      pedido: pedido,
    );
    if (!context.mounted || preparacion == null) return;
    context.read<PreparacionCargaBloc>().add(
      PreparacionCargaPreparacionRegistrada(preparacion),
    );
  }

  Future<void> _confirmarCarga(
    BuildContext context,
    PedidoPreparacion pedido,
  ) async {
    final result = await ConfirmarCargaDialog.show(context, pedido: pedido);
    if (!context.mounted || result == null) return;
    context.read<PreparacionCargaBloc>().add(
      PreparacionCargaPedidoCargado(
        pedidoId: pedido.id,
        paquetes: result.paquetes,
        observacion: result.observacion,
      ),
    );
  }
}

class _SubTabs extends StatelessWidget {
  const _SubTabs({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: [
        Expanded(
          child: _SubTabButton(
            label: 'Preparación de pedidos',
            selected: current == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SubTabButton(
            label: 'Carga del vehículo',
            selected: current == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    ),
  );
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFC500) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
      ),
    ),
  );
}
