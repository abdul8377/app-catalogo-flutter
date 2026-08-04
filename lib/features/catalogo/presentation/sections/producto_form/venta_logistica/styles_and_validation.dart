part of '../venta_logistica_section.dart';

extension _Step4StylesAndValidation on _Step4SalesLogisticsContentPanelState {
  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    String? suffixText,
    IconData? suffixIcon,
    IconData? prefixIcon,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      isDense: dense,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: dense ? 11 : 14,
      ),
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
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade600, width: 2),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: _ink,
      disabledBackgroundColor: const Color(0xFFE6E8EC),
      disabledForegroundColor: _muted,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  ButtonStyle _outlinedButtonStyle({bool compact = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: const BorderSide(color: Color(0xFFBAC4D2)),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 18,
        vertical: compact ? 10 : 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  // ==========================================================================
  // UTILIDADES
  // ==========================================================================

  SalesPresentationDraft? _presentationById(String id) {
    for (final item in _presentations) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  String _packageContainedLabel(LogisticsPackageDraft package) {
    if (package.contentKind == PackageContentKind.baseUnit) {
      return package.contentReferenceId;
    }

    return _presentationById(package.contentReferenceId)?.name ??
        'Presentación eliminada';
  }

  String? _catalogVariantLabel(String? id) {
    if (id == null) {
      return null;
    }

    for (final item in widget.catalogVariants) {
      if (item.id == id) {
        return item.label;
      }
    }
    return null;
  }

  String _contentCounterLabel(List<ProductContentItemDraft> items) {
    if (items.isEmpty) {
      return '0 componentes';
    }

    final units = items.map((item) => item.unit).toSet();
    if (units.length == 1) {
      final unit = units.first;
      final total = items.fold<double>(0, (sum, item) => sum + item.quantity);

      if (unit == 'PZA') {
        return '${_step4PlainNumber(total)} '
            '${total == 1 ? 'pieza' : 'piezas'} en total';
      }

      return '${_step4PlainNumber(total)} $unit en total';
    }

    return '${items.length} '
        '${items.length == 1 ? 'componente registrado' : 'componentes registrados'}';
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    if (_parsePositive(value ?? '') == null) {
      return 'Ingresa un valor mayor que cero.';
    }
    return null;
  }

  double? _parsePositive(String source) {
    final normalized = source.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String? _nullIfEmpty(String source) {
    final value = source.trim();
    return value.isEmpty ? null : value;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? Colors.red.shade700 : _primary,
                foregroundColor: destructive ? Colors.white : _ink,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
