part of '../../pages/dashboard_page.dart';

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisExtent: 126,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, _) => const _SkeletonBox(height: 126),
      ),
      const SizedBox(height: 16),
      const _SkeletonBox(height: 280),
      const SizedBox(height: 16),
      const _SkeletonBox(height: 240),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEAECF0)),
    ),
    padding: const EdgeInsets.all(18),
    child: Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 130,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 40
            ? constraints.maxHeight - 40
            : 0.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEECEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_outlined,
                        size: 30,
                        color: Color(0xFFB42318),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pudimos preparar el Dashboard',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DD),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: _yellow, width: 4),
                        ),
                      ),
                      child: Text(
                        'La información comercial sigue disponible en Pedidos, '
                        'Hojas de pedido y Clientes.',
                        style: GoogleFonts.inter(
                          color: _ink,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: _ink,
                        minimumSize: const Size(170, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Reintentar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _estadoColor(String estado) {
  final value = estado.trim().toLowerCase();
  if (value == 'cancelado') return const Color(0xFFB42318);
  if (value == 'entregado') return const Color(0xFF067647);
  if (value.contains('listo')) return const Color(0xFF087E8B);
  if (value.contains('proceso')) return const Color(0xFF175CD3);
  return const Color(0xFFB54708);
}
