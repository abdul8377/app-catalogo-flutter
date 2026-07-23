import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaDetalleProductos extends StatelessWidget {
  const HojaDetalleProductos({
    required this.hoja,
    required this.onGestionOperativa,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onGestionOperativa;

  @override
  Widget build(BuildContext context) {
    if (hoja.productos.isEmpty) {
      return const Center(
        child: Text('La hoja todavía no contiene productos.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: hoja.productos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final producto = hoja.productos[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              producto.nombre,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${producto.codigo} • ${producto.presentacion}\nRequerido: ${producto.cantidadTotal} • Preparado: ${producto.cantidadPreparada} • Pendiente: ${producto.cantidadPendiente}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Ver gestión operativa',
              onPressed: onGestionOperativa,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        );
      },
    );
  }
}
