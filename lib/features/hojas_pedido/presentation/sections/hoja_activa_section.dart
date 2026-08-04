import 'package:flutter/material.dart';

import '../../domain/entities/hoja_pedido.dart';
import '../widgets/hoja_acciones_rapidas.dart';
import '../widgets/hoja_activa_hero_card.dart';
import '../widgets/hoja_pedidos_recientes.dart';
import '../widgets/hoja_productos_destacados.dart';
import '../widgets/hoja_progreso_operativo.dart';
import '../widgets/hoja_resumen_indicadores.dart';

class HojaActivaSection extends StatelessWidget {
  const HojaActivaSection({
    required this.hoja,
    required this.onVerDetalle,
    required this.onVerPedidos,
    required this.onVerConsolidado,
    required this.onPreparacionCarga,
    required this.onCompletar,
    super.key,
  });

  final HojaPedido hoja;
  final VoidCallback onVerDetalle;
  final VoidCallback onVerPedidos;
  final VoidCallback onVerConsolidado;
  final VoidCallback onPreparacionCarga;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HojaActivaHeroCard(
              hoja: hoja,
              onVerDetalle: onVerDetalle,
              onVerPedidos: onVerPedidos,
              onCompletar: onCompletar,
            ),
            const SizedBox(height: 16),
            HojaResumenIndicadores(
              hoja: hoja,
              onVerPedidos: onVerPedidos,
              onVerProductos: onVerConsolidado,
              onVerPreparacion: onPreparacionCarga,
            ),
            const SizedBox(height: 20),
            HojaProgresoOperativo(hoja: hoja),
            const SizedBox(height: 20),
            HojaPedidosRecientes(
              hoja: hoja,
              onVerTodos: onVerPedidos,
              onVerPedido: (_) => onVerPedidos(),
            ),
            const SizedBox(height: 20),
            HojaProductosDestacados(
              hoja: hoja,
              onVerConsolidado: onVerConsolidado,
            ),
            const SizedBox(height: 20),
            HojaAccionesRapidas(
              onVerPedidos: onVerPedidos,
              onVerConsolidado: onVerConsolidado,
              onPreparacionCarga: onPreparacionCarga,
              onCompletar: onCompletar,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
