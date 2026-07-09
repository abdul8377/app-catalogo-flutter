import 'package:flutter/material.dart';

class BuscadorProductos extends StatelessWidget {
  const BuscadorProductos({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar productos',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: onChanged,
    );
  }
}
