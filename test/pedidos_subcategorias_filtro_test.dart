import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/pedidos/presentation/bloc/nuevo_pedido/pedidos_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nuevo pedido filtra por una o varias subcategorías', () {
    const products = [
      ProductoResumen(
        id: '1',
        codigo: 'PER-001',
        nombre: 'Perno hexagonal',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Pernería',
        subcategoria: 'Pernos hexagonales',
        unidadVenta: 'Ciento',
        precio: 20,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'matriz',
        atributosClave: [],
      ),
      ProductoResumen(
        id: '2',
        codigo: 'TAL-001',
        nombre: 'Taladro',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Herramientas',
        subcategoria: 'Taladros',
        unidadVenta: 'Unidad',
        precio: 150,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'unico',
        atributosClave: [],
      ),
    ];

    final multiple = PedidosState.initial().copyWith(
      loading: false,
      productos: products,
      subcategoriasSeleccionadas: const {'Pernos hexagonales', 'Taladros'},
    );
    expect(multiple.productosFiltrados, hasLength(2));

    final single = multiple.copyWith(
      subcategoriasSeleccionadas: const {'Taladros'},
    );
    expect(single.productosFiltrados.single.codigo, 'TAL-001');
  });
}
