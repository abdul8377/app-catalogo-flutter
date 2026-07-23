import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojaHistorialTimeline extends StatelessWidget {
  const HojaHistorialTimeline({required this.entradas, super.key});

  final List<HistorialHojaEntrada> entradas;

  @override
  Widget build(BuildContext context) {
    if (entradas.isEmpty) {
      return const Center(child: Text('No hay eventos registrados.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entradas.length,
      itemBuilder: (_, index) {
        final entrada = entradas[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == entradas.length - 1
                            ? const Color(0xFFFFC500)
                            : Colors.grey.shade300,
                      ),
                    ),
                    if (index < entradas.length - 1)
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade200),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy • HH:mm').format(entrada.fecha),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entrada.evento,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (entrada.responsable?.trim().isNotEmpty ?? false)
                        Text(
                          'Por: ${entrada.responsable}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
