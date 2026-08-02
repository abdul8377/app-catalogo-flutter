import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pedidos_tabs.dart';

class PedidosHeader extends StatelessWidget implements PreferredSizeWidget {
  const PedidosHeader({
    required this.currentTab,
    required this.totalPedidos,
    required this.onRefresh,
    required this.onTabChanged,
    super.key,
  });

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final int currentTab;
  final int totalPedidos;
  final VoidCallback onRefresh;
  final ValueChanged<int> onTabChanged;

  @override
  Size get preferredSize => const Size.fromHeight(204);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: darkColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gestión de pedidos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$totalPedidos pedidos registrados',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const _LocalPill(),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: PedidosTabs(
              currentIndex: currentTab,
              onChanged: onTabChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocalPill extends StatelessWidget {
  const _LocalPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC500).withValues(alpha: .16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFC500).withValues(alpha: .45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storage_rounded, size: 12, color: Color(0xFFFFC500)),
        const SizedBox(width: 4),
        Text(
          'Operación local',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFFFFC500),
          ),
        ),
      ],
    ),
  );
}
