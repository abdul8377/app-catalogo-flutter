import 'package:app_catalogo/features/catalogo/domain/services/codigo_interno_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodigoInternoGenerator', () {
    test('crea prefijos legibles desde el nombre', () {
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Perno hexagonal'),
        'PER',
      );
      expect(CodigoInternoGenerator.prefijoDesdeNombre('Broca HSS'), 'BRO');
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Alicate universal'),
        'ALI',
      );
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Disco de corte'),
        'DIS',
      );
    });

    test('genera el siguiente correlativo de familia', () {
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: 'Perno hexagonal',
        codigosExistentes: const [
          'PER-001',
          'PER-023',
          'PER-023-001',
          'BRO-100',
        ],
      );

      expect(codigo, 'PER-024');
    });

    test('genera variantes bajo el código de familia', () {
      final codigo = CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: 'PER-023',
        codigosExistentes: const ['PER-023-001', 'PER-023-003', 'PER-024-010'],
      );

      expect(codigo, 'PER-023-004');
      expect(CodigoInternoGenerator.codigoProductoUnico('PER-023'), 'PER-023');
    });
  });
}
