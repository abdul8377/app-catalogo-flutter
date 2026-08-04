import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/preparacion_carga/preparacion_carga_state.dart';

class PreparacionModoChips extends StatelessWidget {
  const PreparacionModoChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final PreparacionModoAgrupacion selected;
  final ValueChanged<PreparacionModoAgrupacion> onChanged;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFC500);
    const darkColor = Color(0xFF1F1F1F);

    return Container(
      color: Colors.white,
      height: 48,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: PreparacionModoAgrupacion.values.map((modo) {
          final seleccionado = selected == modo;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                modo.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.black : darkColor,
                ),
              ),
              selected: seleccionado,
              onSelected: (_) => onChanged(modo),
              backgroundColor: Colors.grey.shade100,
              selectedColor: primaryColor,
              checkmarkColor: Colors.black,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
