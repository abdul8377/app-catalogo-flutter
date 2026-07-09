import 'package:flutter/material.dart';

class ProductoDetallePage extends StatelessWidget {
  const ProductoDetallePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: const Center(child: Text('Detalle del producto seleccionado')),
    );
  }
}
