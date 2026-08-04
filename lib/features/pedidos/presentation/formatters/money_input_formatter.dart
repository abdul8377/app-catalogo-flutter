import 'package:flutter/services.dart';

/// Acepta importes con hasta dos decimales y conserva coma o punto como
/// separador durante la edición.
class MoneyInputFormatter extends TextInputFormatter {
  final _allowed = RegExp(r'^\d*([,.]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _allowed.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

double parseMoney(String value) =>
    double.tryParse(value.replaceAll(',', '.')) ?? 0;
