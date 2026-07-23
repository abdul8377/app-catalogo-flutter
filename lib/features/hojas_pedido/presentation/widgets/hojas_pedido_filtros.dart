import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HojasPedidoFiltros extends StatelessWidget {
  const HojasPedidoFiltros({
    required this.filtro,
    required this.orden,
    required this.onFiltroChanged,
    required this.onOrdenChanged,
    super.key,
  });

  final String filtro;
  final String orden;
  final ValueChanged<String> onFiltroChanged;
  final ValueChanged<String> onOrdenChanged;

  static const filtros = [
    'Todas',
    'Este mes',
    'Con precios pendientes',
    'Con pedidos pendientes',
    'Completamente entregadas',
    'Sin sincronizar',
  ];

  static const ordenes = [
    'Más recientes',
    'Más antiguas',
    'Código',
    'Mayor cantidad de pedidos',
    'Mayor total conocido',
    'Mayor cantidad de productos',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filtros.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final item = filtros[index];
            return FilterChip(
              selected: filtro == item,
              onSelected: (_) => onFiltroChanged(item),
              label: Text(item),
              selectedColor: const Color(0xFFFFC500),
              checkmarkColor: Colors.black,
              labelStyle: GoogleFonts.inter(
                fontWeight: filtro == item ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: orden,
            isExpanded: true,
            items: ordenes
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onOrdenChanged(value);
            },
          ),
        ),
      ),
    ],
  );
}
