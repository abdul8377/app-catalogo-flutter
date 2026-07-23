import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_resumen.dart';

class PedidoSyncBadge extends StatelessWidget {
  const PedidoSyncBadge({required this.pedido, super.key});

  final PedidoResumen pedido;

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 3),
          Text(
            config.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _SyncBadgeConfig _config() {
    if (pedido.syncError != null) {
      return const _SyncBadgeConfig(
        label: 'Error',
        icon: Icons.sync_problem,
        color: Color(0xFFC62828),
      );
    }
    if (pedido.sincronizado) {
      return const _SyncBadgeConfig(
        label: 'Sincronizado',
        icon: Icons.cloud_done,
        color: Color(0xFF2E7D32),
      );
    }
    if (pedido.guardadoLocal) {
      return const _SyncBadgeConfig(
        label: 'Pendiente',
        icon: Icons.save,
        color: Color(0xFFE65100),
      );
    }
    return const _SyncBadgeConfig(
      label: 'Sin sinc',
      icon: Icons.sync_problem,
      color: Color(0xFFC62828),
    );
  }
}

class _SyncBadgeConfig {
  const _SyncBadgeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
