enum TipoValorTecnico { numero, rango, compuesto, texto }

class EntradaValorUnidad {
  const EntradaValorUnidad({required this.valor, required this.unidad});

  final String valor;
  final String unidad;
}

class ValorTecnicoParseado {
  const ValorTecnicoParseado({
    required this.original,
    required this.unidad,
    required this.tipo,
    required this.valores,
  });

  final String original;
  final String unidad;
  final TipoValorTecnico tipo;
  final List<double> valores;

  bool get esNumerico => tipo != TipoValorTecnico.texto && valores.isNotEmpty;

  double? get minimo {
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a < b ? a : b);
  }

  double? get maximo {
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a > b ? a : b);
  }

  bool get tieneDosExtremos => valores.length == 2;
}

abstract final class ValorTecnicoParser {
  static const String _numberToken =
      r'(?:[-+]?\d+\s+\d+\s*/\s*\d+|'
      r'[-+]?\d+\s*/\s*\d+|'
      r'[-+]?\d+(?:[.,]\d+)?)';

  static final RegExp _range = RegExp(
    '^($_numberToken)\\s*(?:-|–|—|a)\\s*($_numberToken)\$',
    caseSensitive: false,
  );

  static final RegExp _compound = RegExp(
    r'^([-+]?\d+(?:[.,]\d+)?)\s*/\s*([-+]?\d+(?:[.,]\d+)?)$',
  );

  static final RegExp _mixed = RegExp(r'^([-+]?\d+)\s+(\d+)\s*/\s*(\d+)$');

  static final RegExp _fraction = RegExp(r'^([-+]?\d+)\s*/\s*(\d+)$');

  static final RegExp _decimal = RegExp(r'^[-+]?\d+(?:[.,]\d+)?$');

  static ValorTecnicoParseado parse(String raw, {String unidad = ''}) {
    final original = raw.trim();
    final cleanUnit = unidad.trim();

    final range = _range.firstMatch(original);
    if (range != null) {
      final first = parseNumero(range.group(1)!);
      final second = parseNumero(range.group(2)!);
      if (first != null && second != null) {
        return ValorTecnicoParseado(
          original: original,
          unidad: cleanUnit,
          tipo: TipoValorTecnico.rango,
          valores: [first, second],
        );
      }
    }

    final compound = _compound.firstMatch(original);
    if (compound != null) {
      final first = double.tryParse(compound.group(1)!.replaceAll(',', '.'));
      final second = double.tryParse(compound.group(2)!.replaceAll(',', '.'));
      if (first != null &&
          second != null &&
          _esCompuesto(first, second, cleanUnit)) {
        return ValorTecnicoParseado(
          original: original,
          unidad: cleanUnit,
          tipo: TipoValorTecnico.compuesto,
          valores: [first, second],
        );
      }
    }

    final number = parseNumero(original);
    if (number != null) {
      return ValorTecnicoParseado(
        original: original,
        unidad: cleanUnit,
        tipo: TipoValorTecnico.numero,
        valores: [number],
      );
    }

    return ValorTecnicoParseado(
      original: original,
      unidad: cleanUnit,
      tipo: TipoValorTecnico.texto,
      valores: const [],
    );
  }

  static double? parseNumero(String raw) {
    final value = raw.trim();

    final mixed = _mixed.firstMatch(value);
    if (mixed != null) {
      final whole = double.parse(mixed.group(1)!);
      final numerator = double.parse(mixed.group(2)!);
      final denominator = double.parse(mixed.group(3)!);
      if (denominator == 0) return null;
      final sign = whole < 0 ? -1.0 : 1.0;
      return whole + sign * numerator / denominator;
    }

    final fraction = _fraction.firstMatch(value);
    if (fraction != null) {
      final numerator = double.parse(fraction.group(1)!);
      final denominator = double.parse(fraction.group(2)!);
      return denominator == 0 ? null : numerator / denominator;
    }

    if (!_decimal.hasMatch(value)) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  static EntradaValorUnidad separarValorUnidad(String raw) {
    final original = raw.trim();
    if (original.isEmpty) {
      return const EntradaValorUnidad(valor: '', unidad: '');
    }

    final match = RegExp(
      r'^(.+?)\s*([A-Za-zµ°%″"][A-Za-z0-9µ°%″"/.\-·]*)$',
    ).firstMatch(original);

    if (match == null) {
      return EntradaValorUnidad(valor: original, unidad: '');
    }

    final value = match.group(1)!.trim();
    final unit = match.group(2)!.trim();
    final parsed = parse(value, unidad: unit);

    if (!parsed.esNumerico) {
      return EntradaValorUnidad(valor: original, unidad: '');
    }

    return EntradaValorUnidad(valor: value, unidad: unit);
  }

  static bool _esCompuesto(double first, double second, String unidad) {
    final normalizedUnit = unidad.trim().toLowerCase();
    if (normalizedUnit == 'hz') return true;
    return first.abs() >= 10 && second.abs() >= 10;
  }
}
