import 'package:flutter/material.dart';

class HojasPedidoBuscador extends StatelessWidget {
  const HojasPedidoBuscador({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey(value),
    initialValue: value,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: 'Buscar por código, vendedor, cliente, pedido o producto...',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
  );
}
