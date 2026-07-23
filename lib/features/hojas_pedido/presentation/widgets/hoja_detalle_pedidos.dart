import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaDetallePedidos extends StatefulWidget {
  const HojaDetallePedidos({
    required this.hoja,
    required this.onVerPedido,
    super.key,
  });

  final HojaPedido hoja;
  final ValueChanged<PedidoEnHoja> onVerPedido;

  @override
  State<HojaDetallePedidos> createState() => _HojaDetallePedidosState();
}

class _HojaDetallePedidosState extends State<HojaDetallePedidos> {
  String filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    final pedidos = widget.hoja.pedidos.where((pedido) {
      switch (filtro) {
        case 'Pendientes':
          return pedido.estadoLabel == 'Pendiente';
        case 'Sin precio':
          return !pedido.tienePrecio;
        case 'Preparados':
          return pedido.progresoPreparacion >= 1;
        case 'Listos':
          return pedido.estadoLabel == 'Listo para entregar';
        default:
          return true;
      }
    }).toList();
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            children: [
              for (final item in const [
                'Todos',
                'Pendientes',
                'Sin precio',
                'Preparados',
                'Listos',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: filtro == item,
                    onSelected: (_) => setState(() => filtro = item),
                    label: Text(item),
                    selectedColor: const Color(0xFFFFC500),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: pedidos.isEmpty
              ? const Center(child: Text('No hay pedidos para este filtro.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: pedidos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final pedido = pedidos[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => widget.onVerPedido(pedido),
                        title: Text(
                          '${pedido.codigo} • ${pedido.cliente}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM').format(pedido.fecha)} • ${pedido.cantidadProductos} productos • ${pedido.tienePrecio ? 'S/ ${pedido.total!.toStringAsFixed(2)}' : 'Pendiente'} • ${pedido.estadoLabel}',
                        ),
                        trailing: Text(
                          'Prep: ${(pedido.progresoPreparacion * 100).round()}%',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
