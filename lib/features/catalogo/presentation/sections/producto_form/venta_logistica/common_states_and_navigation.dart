part of '../venta_logistica_section.dart';

extension _Step4CommonStatesAndNavigation
    on _Step4SalesLogisticsContentPanelState {
  Widget _notApplicableState({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onChange,
  }) {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F6ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: _success),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onChange,
              style: _outlinedButtonStyle(),
              child: const Text('Cambiar respuesta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: _muted),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _neutralNote(String message, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    Color background = Colors.white,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _statusPill(
    String label, {
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildBottomNavigation() {
    String nextLabel;
    switch (_section) {
      case Step4Section.salesPresentations:
        nextLabel = 'Siguiente: empaques';
        break;
      case Step4Section.logisticsPackages:
        nextLabel = 'Siguiente: contenido';
        break;
      case Step4Section.productContent:
        nextLabel = 'Siguiente: precios';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final backButton = OutlinedButton(
              onPressed: _handleBack,
              style: _outlinedButtonStyle(),
              child: const Text('Anterior'),
            );
            final nextButton = FilledButton(
              onPressed: _handleNext,
              style: _primaryButtonStyle(),
              child: Text(nextLabel),
            );
            const progress = Text(
              'Paso 4 de 7',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nextButton,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      backButton,
                      const Expanded(child: progress),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                backButton,
                const Expanded(child: progress),
                nextButton,
              ],
            );
          },
        ),
      ),
    );
  }
}
