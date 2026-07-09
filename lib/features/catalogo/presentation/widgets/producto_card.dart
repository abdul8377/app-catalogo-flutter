import 'package:flutter/material.dart';

import '../../domain/entities/producto.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({required this.producto, super.key});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(producto.nombre),
        subtitle: Text(producto.descripcion ?? 'Sin descripcion'),
        trailing: Text('S/ ${producto.precio.toStringAsFixed(2)}'),
      ),
    );
  }
}
