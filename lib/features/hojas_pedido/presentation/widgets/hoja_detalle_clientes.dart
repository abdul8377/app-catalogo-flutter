import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaDetalleClientes extends StatelessWidget {
  const HojaDetalleClientes({
    required this.hoja,
    required this.onVerPedidos,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerPedidos;

  @override
  Widget build(BuildContext context) {
    if (hoja.clientes.isEmpty) {
      return const Center(child: Text('La hoja todavía no contiene clientes.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: hoja.clientes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final cliente = hoja.clientes[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nombre,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cliente.cantidadPedidos} pedidos • ${cliente.cantidadProductos} productos',
                ),
                Text(
                  'Total conocido — incluye IGV: S/ ${cliente.subtotalConocido.toStringAsFixed(2)}',
                ),
                Text(
                  'Teléfono: ${cliente.telefono.isEmpty ? 'No registrado' : cliente.telefono}',
                ),
                Text(
                  'Dirección: ${cliente.direccion.isEmpty ? 'No registrada' : cliente.direccion}',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onVerPedidos,
                  child: const Text('Ver pedidos'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
