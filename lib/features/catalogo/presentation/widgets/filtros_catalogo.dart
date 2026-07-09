import 'package:flutter/material.dart';

class FiltrosCatalogo extends StatelessWidget {
  const FiltrosCatalogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: const [
          FilterChip(label: Text('Todos'), selected: true, onSelected: null),
          FilterChip(
            label: Text('Disponibles'),
            selected: false,
            onSelected: null,
          ),
        ],
      ),
    );
  }
}
