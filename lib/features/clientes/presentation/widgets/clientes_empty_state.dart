import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientesEmptyState extends StatelessWidget {
  const ClientesEmptyState({required this.onLimpiarFiltros, super.key});

  final VoidCallback onLimpiarFiltros;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No se encontraron clientes',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba cambiando los filtros o registra uno nuevo',
            style: GoogleFonts.inter(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onLimpiarFiltros,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar filtros'),
          ),
        ],
      ),
    ),
  );
}
