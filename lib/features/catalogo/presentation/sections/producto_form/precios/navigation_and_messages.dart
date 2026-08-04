part of '../precios_section.dart';

extension _Step5NavigationAndMessages on _Step5PricingPanelState {
  Future<void> _continueToImages() async {
    if (_totalPendingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Continuar con $_totalPendingCount pendientes'),
            content: const Text(
              'Puedes continuar y guardar el producto como borrador. '
              'Sin embargo, las combinaciones pendientes impedirán '
              'la activación definitiva en el paso 7.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Revisar precios'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Continuar como borrador'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    widget.onNext(_draft);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
