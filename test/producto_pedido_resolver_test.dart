import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/pedidos/domain/services/producto_pedido_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una combinación sin precio se permite como Por cotizar', () {
    final resolved = ProductoPedidoResolver.resolver(
      _producto(precios: const []),
    );

    final price = resolved.variantesActivas.single.presentaciones.single
        .precioParaLista('regular');

    expect(price, isNotNull);
    expect(price!.tipo, TipoPrecioPedido.cotizar);
    expect(price.permiteAgregar, isTrue);
    expect(price.precioPara(1), isNull);
  });

  test('una configuración explícitamente pendiente continúa bloqueada', () {
    final resolved = ProductoPedidoResolver.resolver(
      _producto(
        precios: const [
          {
            'list_id': 'regular',
            'variant_id': 'var-1',
            'presentation_id': 'ciento',
            'configuration': 'pending',
            'fixed_price': null,
            'ranges': [],
          },
        ],
      ),
    );

    final price = resolved.variantesActivas.single.presentaciones.single
        .precioParaLista('regular');

    expect(price, isNotNull);
    expect(price!.tipo, TipoPrecioPedido.pendiente);
    expect(price.permiteAgregar, isFalse);
  });
}

ProductoDetalle _producto({required List<Map<String, Object?>> precios}) =>
    ProductoDetalle(
      id: 'family',
      codigo: 'PER-FAM',
      nombre: 'Perno hexagonal 1/4 x 4',
      descripcion: '',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      subcategoria: 'Pernos',
      tipoRegistro: 'matriz',
      atributos: const {'Material': 'Acero'},
      variantes: const [
        ProductoVariante(
          id: 'var-1',
          sku: 'PER-025X4',
          nombreCorto: 'Perno hexagonal 1/4 x 4',
          atributos: [
            AtributoProductoVariante(
              nombre: 'Diámetro',
              valor: '1/4',
              unidad: 'in',
            ),
            AtributoProductoVariante(nombre: 'Largo', valor: '4', unidad: 'in'),
          ],
        ),
      ],
      presentaciones: const [
        PresentacionProducto(nombre: 'Ciento', unidad: '100 UND'),
      ],
      precios: const [],
      ventaLogisticaContenido: const {
        'presentations': [
          {
            'id': 'ciento',
            'name': 'Ciento',
            'base_unit': 'UND',
            'equivalent_to': 100,
            'minimum_order': 1,
            'purchase_increment': 1,
            'assigned_variant_ids': ['var-1'],
            'default_variant_ids': ['var-1'],
            'variant_rules': [],
          },
        ],
      },
      preciosConfigurados: {
        'lists': const [
          {
            'id': 'regular',
            'name': 'Regular',
            'currency_code': 'PEN',
            'includes_igv': true,
          },
        ],
        'prices': precios,
      },
      activo: true,
      creadoEn: DateTime(2026),
    );
