import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hoja_sync_badge.dart';
import 'hojas_pedido_tabs.dart';

class HojasPedidoHeader extends StatelessWidget implements PreferredSizeWidget {
  const HojasPedidoHeader({
    required this.totalHojas,
    required this.currentTab,
    required this.actualizando,
    required this.tieneHojaActiva,
    required this.onRefresh,
    required this.onTabChanged,
    required this.onCrearHoja,
    super.key,
  });

  final int totalHojas;
  final int currentTab;
  final bool actualizando;
  final bool tieneHojaActiva;
  final VoidCallback onRefresh;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onCrearHoja;

  @override
  Size get preferredSize => const Size.fromHeight(220);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return Container(
        color: const Color(0xFF1F1F1F),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  _TitleBlock(totalHojas: totalHojas),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const HojaSyncBadge(
                        sincronizado: false,
                        oscuro: true,
                        compacto: true,
                      ),
                      if (!tieneHojaActiva)
                        _NewSheetButton(onPressed: onCrearHoja),
                      _RefreshButton(
                        actualizando: actualizando,
                        onRefresh: onRefresh,
                      ),
                    ],
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _TitleBlock(totalHojas: totalHojas),
                            const SizedBox(width: 14),
                            const HojaSyncBadge(
                              sincronizado: false,
                              oscuro: true,
                            ),
                          ],
                        ),
                      ),
                      if (!tieneHojaActiva)
                        _NewSheetButton(onPressed: onCrearHoja),
                      const SizedBox(width: 4),
                      _RefreshButton(
                        actualizando: actualizando,
                        onRefresh: onRefresh,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                HojasPedidoTabs(
                  currentTab: currentTab,
                  onChanged: onTabChanged,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.totalHojas});

  final int totalHojas;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Hojas de pedido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '$totalHojas hojas registradas',
        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
      ),
    ],
  );
}

class _NewSheetButton extends StatelessWidget {
  const _NewSheetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add, size: 18),
    label: const Text('Nueva hoja'),
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFFC500),
      foregroundColor: Colors.black,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  );
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.actualizando, required this.onRefresh});

  final bool actualizando;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Actualizar',
    onPressed: actualizando ? null : onRefresh,
    icon: actualizando
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.refresh, color: Colors.white),
  );
}
