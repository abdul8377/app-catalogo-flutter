import 'package:app_catalogo/core/navigation/app_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva el contrato de índices de todos los destinos', () {
    const expected = <AppDestination>[
      AppDestination.home,
      AppDestination.catalogo,
      AppDestination.clientes,
      AppDestination.nuevoPedido,
      AppDestination.pedidos,
      AppDestination.hojasPedido,
      AppDestination.dashboard,
      AppDestination.estructuraCatalogo,
    ];

    expect(AppDestination.values, expected);
    for (var index = 0; index < expected.length; index++) {
      expect(expected[index].navigationIndex, index);
      expect(AppDestination.tryFromIndex(index), expected[index]);
    }
  });

  test('la conversión segura rechaza índices desconocidos', () {
    expect(AppDestination.tryFromIndex(-1), isNull);
    expect(AppDestination.tryFromIndex(8), isNull);
    expect(AppDestination.tryFromIndex(999), isNull);
  });
}
