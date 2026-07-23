import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HojaAccionesRapidas extends StatelessWidget {
  const HojaAccionesRapidas({
    required this.onVerPedidos,
    required this.onVerConsolidado,
    required this.onPreparacionCarga,
    required this.onCompletar,
    super.key,
  });

  final VoidCallback onVerPedidos;
  final VoidCallback onVerConsolidado;
  final VoidCallback onPreparacionCarga;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Acciones rápidas',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 700
              ? (constraints.maxWidth - 30) / 4
              : (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _button(width, Icons.receipt_long, 'Ver pedidos', onVerPedidos),
              _button(width, Icons.inventory, 'Consolidado', onVerConsolidado),
              _button(
                width,
                Icons.local_shipping,
                'Preparación',
                onPreparacionCarga,
              ),
              _button(
                width,
                Icons.check_circle_outline,
                'Completar hoja',
                onCompletar,
                primary: true,
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _button(
    double width,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) => SizedBox(
    width: width,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1F1F1F),
        backgroundColor: primary ? const Color(0xFFFFC500) : Colors.white,
        side: BorderSide(
          color: primary ? const Color(0xFFFFC500) : const Color(0xFFE0E0E0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
  );
}
