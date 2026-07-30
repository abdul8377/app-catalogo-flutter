import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/domain/services/valor_tecnico_parser.dart';

void main() {
  group('ValorTecnicoParser', () {
    test('normaliza fracciones sin perder el texto original', () {
      final parsed = ValorTecnicoParser.parse('1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.minimo, closeTo(0.5, 0.000001));
      expect(parsed.original, '1/2');
      expect(parsed.unidad, '″');
    });

    test('normaliza números mixtos', () {
      final parsed = ValorTecnicoParser.parse('1 1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.minimo, closeTo(1.5, 0.000001));
    });

    test('reconoce un rango con unidad', () {
      final separated = ValorTecnicoParser.separarValorUnidad('220–240 V');
      final parsed = ValorTecnicoParser.parse(
        separated.valor,
        unidad: separated.unidad,
      );

      expect(separated.valor, '220–240');
      expect(separated.unidad, 'V');
      expect(parsed.tipo, TipoValorTecnico.rango);
      expect(parsed.minimo, 220);
      expect(parsed.maximo, 240);
    });

    test('reconoce frecuencia compuesta 50/60 Hz', () {
      final separated = ValorTecnicoParser.separarValorUnidad('50/60 Hz');
      final parsed = ValorTecnicoParser.parse(
        separated.valor,
        unidad: separated.unidad,
      );

      expect(parsed.tipo, TipoValorTecnico.compuesto);
      expect(parsed.valores, [50, 60]);
    });

    test('mantiene 1/2 como fracción y no como valor compuesto', () {
      final parsed = ValorTecnicoParser.parse('1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.valores, [0.5]);
    });

    test('no separa una descripción textual como valor y unidad', () {
      final separated = ValorTecnicoParser.separarValorUnidad(
        'Acero inoxidable 304',
      );

      expect(separated.valor, 'Acero inoxidable 304');
      expect(separated.unidad, isEmpty);
    });
  });

  test('AtributoProductoVariante conserva rango y selección múltiple', () {
    const original = AtributoProductoVariante(
      nombre: 'Voltaje',
      valor: '220–240',
      unidad: 'V',
      valorNormalizado: 220,
      valorMaximo: 240,
      valores: ['Monofásico', 'Trifásico'],
    );

    final restored = AtributoProductoVariante.fromMap(original.toMap());

    expect(restored.valor, '220–240');
    expect(restored.valorNormalizado, 220);
    expect(restored.valorMaximo, 240);
    expect(restored.valores, ['Monofásico', 'Trifásico']);
  });
}
