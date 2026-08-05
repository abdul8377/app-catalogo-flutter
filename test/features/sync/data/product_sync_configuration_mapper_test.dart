import 'dart:convert';
import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/sync/data/mappers/product_sync_configuration_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late AppDatabase appDatabase;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'product_sync_configuration_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: path.join(temporaryDirectory.path, 'catalogo.db'),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('exporta y restaura las configuraciones completas de SQLite', () async {
    final database = await appDatabase.database;
    const productId = 'product-configuration-1';
    const salesConfiguration = <String, Object?>{
      'uses_logistics_packages': true,
      'logistics_packages': [
        {'id': 'package-1', 'name': 'Caja master'},
      ],
      'has_product_content': true,
      'content_items': [
        {'name': 'Tuerca', 'quantity': 1},
      ],
    };
    const pricingConfiguration = <String, Object?>{
      'lists': [
        {'id': 'list-1', 'name': 'General', 'currency_code': 'PEN'},
      ],
      'prices': [
        {
          'list_id': 'list-1',
          'variant_id': 'variant-1',
          'presentation_id': 'presentation-1',
          'configuration': 'quantity',
          'ranges': [
            {'from': 1, 'to': 99, 'price': 2.5},
          ],
        },
      ],
    };
    const imageConfiguration = <String, Object?>{
      'family_images': [
        {'id': 'image-1', 'is_primary': true},
      ],
      'exceptions': [],
    };

    await database.insert('productos', {
      'id': productId,
      'codigo': 'CONFIG-001',
      'nombre': 'Producto con configuración completa',
      'descripcion': 'Prueba de reconstrucción completa',
      'empresa': 'Empresa',
      'marca': 'Marca',
      'categoria': 'Categoría',
      'subcategoria': '',
      'tipo_registro': 'producto_unico',
      'atributos_json': '{}',
      'variantes_json': jsonEncode([
        {
          'id': 'variant-1',
          'sku': 'CONFIG-001-U',
          'nombre_corto': 'Producto con configuración completa',
          'atributos': <String, Object?>{},
        },
      ]),
      'presentaciones_json': jsonEncode([
        {
          'id': 'presentation-1',
          'nombre': 'Unidad',
          'unidad': 'UND',
          'equivalencia': 1,
        },
      ]),
      'venta_logistica_json': jsonEncode(salesConfiguration),
      'precios_configurados_json': jsonEncode(pricingConfiguration),
      'imagenes_configuradas_json': jsonEncode(imageConfiguration),
      'precios_json': '[]',
      'unidad_venta': 'Unidad',
      'precio': null,
      'sin_precio': 1,
      'activo': 1,
      'imagen_path': null,
      'imagenes_json': '[]',
      'creado_en': DateTime.utc(2026, 8, 4).toIso8601String(),
    });
    await database.insert('producto_variantes_catalogo', {
      'id': 'variant-1',
      'producto_id': productId,
      'sku': 'CONFIG-001-U',
      'codigo_proveedor': '',
      'nombre_corto': 'Producto con configuración completa',
      'estado': 1,
    });

    const mapper = ProductSyncConfigurationMapper();
    final aggregate = await mapper.exportProductAggregate(
      database,
      productId: productId,
      operation: 'UPSERT',
    );

    expect(aggregate['salesConfiguration'], salesConfiguration);
    expect(aggregate['pricingConfiguration'], pricingConfiguration);
    expect(aggregate['imageConfiguration'], imageConfiguration);

    final restoredSales = <String, Object?>{
      ...salesConfiguration,
      'uses_logistics_packages': false,
    };
    final restoredAggregate = <String, Object?>{
      ...aggregate,
      'salesConfiguration': restoredSales,
      'pricingConfiguration': pricingConfiguration,
      'imageConfiguration': imageConfiguration,
    };
    await mapper.applyProductAggregate(
      database,
      productId: productId,
      operation: 'UPSERT',
      payload: restoredAggregate,
    );

    final row = (await database.query(
      'productos',
      columns: const [
        'venta_logistica_json',
        'precios_configurados_json',
        'imagenes_configuradas_json',
      ],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    )).single;

    expect(jsonDecode(row['venta_logistica_json']! as String), restoredSales);
    expect(
      jsonDecode(row['precios_configurados_json']! as String),
      pricingConfiguration,
    );
    expect(
      jsonDecode(row['imagenes_configuradas_json']! as String),
      imageConfiguration,
    );
  });
}
