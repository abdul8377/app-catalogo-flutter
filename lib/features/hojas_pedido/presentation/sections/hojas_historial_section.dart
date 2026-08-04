import 'package:flutter/material.dart';

import '../../domain/entities/hoja_pedido.dart';
import '../widgets/hoja_pedido_card.dart';
import '../widgets/hojas_pedido_buscador.dart';
import '../widgets/hojas_pedido_empty_state.dart';
import '../widgets/hojas_pedido_filtros.dart';

class HojasHistorialSection extends StatelessWidget {
  const HojasHistorialSection({
    required this.hojas,
    required this.busqueda,
    required this.filtro,
    required this.orden,
    required this.onBusquedaChanged,
    required this.onFiltroChanged,
    required this.onOrdenChanged,
    required this.onLimpiarFiltros,
    required this.onCrearHoja,
    required this.onVerHoja,
    required this.onVerPedidos,
    required this.onVerConsolidado,
    super.key,
  });

  final List<HojaPedido> hojas;
  final String busqueda;
  final String filtro;
  final String orden;
  final ValueChanged<String> onBusquedaChanged;
  final ValueChanged<String> onFiltroChanged;
  final ValueChanged<String> onOrdenChanged;
  final VoidCallback onLimpiarFiltros;
  final VoidCallback onCrearHoja;
  final ValueChanged<HojaPedido> onVerHoja;
  final ValueChanged<HojaPedido> onVerPedidos;
  final ValueChanged<HojaPedido> onVerConsolidado;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            HojasPedidoBuscador(value: busqueda, onChanged: onBusquedaChanged),
            const SizedBox(height: 10),
            HojasPedidoFiltros(
              filtro: filtro,
              orden: orden,
              onFiltroChanged: onFiltroChanged,
              onOrdenChanged: onOrdenChanged,
            ),
          ],
        ),
      ),
      Expanded(
        child: hojas.isEmpty
            ? HojasPedidoEmptyState(
                icon: Icons.search_off,
                title: busqueda.isEmpty && filtro == 'Todas'
                    ? 'Todavía no existen hojas completadas'
                    : 'No se encontraron hojas',
                message: busqueda.isEmpty && filtro == 'Todas'
                    ? 'Cuando completes una hoja aparecerá en este historial.'
                    : 'Prueba cambiando los filtros o la búsqueda.',
                actionLabel: busqueda.isEmpty && filtro == 'Todas'
                    ? 'Crear nueva hoja'
                    : 'Limpiar filtros',
                onAction: busqueda.isEmpty && filtro == 'Todas'
                    ? onCrearHoja
                    : onLimpiarFiltros,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 2 : 1;
                  if (columns == 1) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: hojas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, index) => _card(hojas[index]),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 600,
                    ),
                    itemCount: hojas.length,
                    itemBuilder: (_, index) {
                      return _card(hojas[index]);
                    },
                  );
                },
              ),
      ),
    ],
  );

  Widget _card(HojaPedido hoja) => HojaPedidoCard(
    hoja: hoja,
    onVerHoja: () => onVerHoja(hoja),
    onVerPedidos: () => onVerPedidos(hoja),
    onVerConsolidado: () => onVerConsolidado(hoja),
  );
}
