part of '../imagenes_section.dart';

extension _Step6NavigationAndCommonWidgets on _Step6ImagesPanelState {
  Widget _buildBottomNavigation() {
    final primaryReady = _draft.familyPrimary != null;
    final statusText = _hasProcessing
        ? 'Hay imágenes procesándose'
        : _hasFailed
        ? 'Reintenta o elimina las imágenes con error'
        : primaryReady
        ? 'Imagen principal lista'
        : 'Falta una imagen principal para activar';
    final statusIcon = _hasProcessing
        ? Icons.hourglass_top
        : _hasFailed
        ? Icons.error_outline
        : primaryReady
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final back = OutlinedButton(
            onPressed: widget.onBack,
            style: _outlinedStyle(),
            child: const Text('Anterior'),
          );
          final status = Row(
            children: [
              Icon(
                statusIcon,
                color: primaryReady && !_hasProcessing && !_hasFailed
                    ? _success
                    : _muted,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$statusText · Paso 6 de 7',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ),
            ],
          );
          final next = FilledButton(
            onPressed: _hasProcessing ? null : _continueToReview,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(220, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Siguiente: revisar y activar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                next,
                const SizedBox(height: 10),
                Row(
                  children: [
                    back,
                    const SizedBox(width: 12),
                    Expanded(child: status),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              back,
              const Spacer(),
              Flexible(child: status),
              const Spacer(),
              next,
            ],
          );
        },
      ),
    );
  }

  Widget _panel({required Widget child, Color background = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 17),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _selection, width: 2),
      ),
    );
  }
}
