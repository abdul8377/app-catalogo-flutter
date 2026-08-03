abstract final class CodigoInternoGenerator {
  static const _palabrasIgnoradas = {
    'DE',
    'DEL',
    'LA',
    'LAS',
    'EL',
    'LOS',
    'PARA',
    'CON',
    'Y',
    'EN',
    'POR',
    'UN',
    'UNA',
  };

  static String prefijoDesdeNombre(String nombre) {
    var normalizado = nombre.trim().toUpperCase();
    const reemplazos = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    reemplazos.forEach((origen, destino) {
      normalizado = normalizado.replaceAll(origen, destino);
    });
    final palabras = normalizado
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((palabra) => palabra.isNotEmpty)
        .toList();
    final significativas = palabras
        .where((palabra) => !_palabrasIgnoradas.contains(palabra))
        .toList();
    final base = significativas.isNotEmpty
        ? significativas.first
        : palabras.isNotEmpty
        ? palabras.first
        : 'PRD';
    final letras = base.replaceAll(RegExp(r'[^A-Z]'), '');
    if (letras.length >= 3) return letras.substring(0, 3);
    final combinadas = significativas.join().replaceAll(RegExp(r'[^A-Z]'), '');
    return '${combinadas}PRD'.substring(0, 3);
  }

  static String siguienteProducto({
    required String nombreBase,
    required Iterable<String> codigosExistentes,
  }) {
    final prefijo = prefijoDesdeNombre(nombreBase);
    final pattern = RegExp('^${RegExp.escape(prefijo)}-(\\d+)\$');
    var mayor = 0;
    for (final codigo in codigosExistentes) {
      final match = pattern.firstMatch(codigo.trim().toUpperCase());
      final numero = int.tryParse(match?.group(1) ?? '');
      if (numero != null && numero > mayor) mayor = numero;
    }
    return '$prefijo-${(mayor + 1).toString().padLeft(3, '0')}';
  }

  static String codigoProductoUnico(String codigoFamilia) {
    final limpio = codigoFamilia.trim().toUpperCase();
    return limpio.isEmpty ? 'PRD-001' : limpio;
  }

  static String siguienteVariante({
    required String codigoFamilia,
    required Iterable<String> codigosExistentes,
  }) {
    final familia = codigoFamilia.trim().toUpperCase().isEmpty
        ? 'PRD-001'
        : codigoFamilia.trim().toUpperCase();
    final pattern = RegExp('^${RegExp.escape(familia)}-(\\d+)\$');
    var mayor = 0;
    for (final codigo in codigosExistentes) {
      final match = pattern.firstMatch(codigo.trim().toUpperCase());
      final numero = int.tryParse(match?.group(1) ?? '');
      if (numero != null && numero > mayor) mayor = numero;
    }
    return '$familia-${(mayor + 1).toString().padLeft(3, '0')}';
  }
}
