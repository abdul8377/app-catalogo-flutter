import 'dart:convert';
import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/sync/data/mappers/product_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late Database database;
  const mapper = ProductSyncMapper();

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_product_sync_test_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: path.join(tempDirectory.path, 'catalogo.db'),
    );
    database = await appDatabase.database;
    await _insertCompleteProduct(database);
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'exporta PRODUCT completo y coalesce los triggers secundarios',
    () async {
      final aggregate = await mapper.exportProductAggregate(
        database,
        productId: 'product-1',
        operation: 'UPSERT',
      );
      final events = await database.query(
        'sync_queue',
        where:
            "entidad = 'PRODUCT' AND entidad_id = 'product-1' "
            "AND estado IN ('pending', 'retry')",
      );

      expect(aggregate['attributes'], isA<Map>());
      expect(aggregate['variants'], isA<List>());
      expect(aggregate['presentations'], isA<List>());
      expect(aggregate['prices'], isA<List>());
      expect(aggregate['images'], isA<List>());
      expect(aggregate['familyAxes'], hasLength(1));
      expect(aggregate['attributeValues'], hasLength(1));
      expect(aggregate['attributeOptions'], hasLength(1));
      expect(events, hasLength(1));
      expect(events.single['entidad'], 'PRODUCT');
      expect(events.single['entidad_id'], 'product-1');
      expect(
        await database.query(
          'sync_queue',
          where:
              "entidad IN ('PRODUCT_VARIANT', 'PRODUCT_FAMILY_AXIS', "
              "'PRODUCT_ATTRIBUTE', 'PRODUCT_ATTRIBUTE_OPTION')",
        ),
        isEmpty,
      );
    },
  );

  test('aplica las cinco tablas en una sola transaccion', () async {
    final aggregate = await mapper.exportProductAggregate(
      database,
      productId: 'product-1',
      operation: 'UPSERT',
    );
    aggregate['name'] = 'Producto remoto';

    await database.transaction((transaction) async {
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 1,
      }, where: 'id = 1');
      await mapper.applyProductAggregate(
        transaction,
        productId: 'product-1',
        operation: 'UPSERT',
        payload: aggregate,
      );
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 0,
      }, where: 'id = 1');
    });

    expect(
      (await database.query(
        'productos',
        where: 'id = ?',
        whereArgs: const ['product-1'],
      )).single['nombre'],
      'Producto remoto',
    );
    expect(await database.query('producto_variantes_catalogo'), hasLength(1));
    expect(await database.query('producto_familia_ejes'), hasLength(1));
    expect(await database.query('producto_atributos'), hasLength(1));
    expect(await database.query('producto_atributo_opciones'), hasLength(1));
  });

  test('revierte todo PRODUCT si falla una parte de la proyeccion', () async {
    final aggregate = await mapper.exportProductAggregate(
      database,
      productId: 'product-1',
      operation: 'UPSERT',
    );
    aggregate['name'] = 'Nombre que debe revertirse';
    aggregate['familyAxes'] = const [
      {
        'producto_id': 'product-1',
        'categoria_atributo_id': 'attribute-missing',
        'orden': 0,
      },
    ];

    await expectLater(
      database.transaction((transaction) async {
        await transaction.update('sync_runtime_context', const {
          'applying_remote': 1,
        }, where: 'id = 1');
        await mapper.applyProductAggregate(
          transaction,
          productId: 'product-1',
          operation: 'UPSERT',
          payload: aggregate,
        );
      }),
      throwsA(isA<DatabaseException>()),
    );

    final product = (await database.query(
      'productos',
      where: 'id = ?',
      whereArgs: const ['product-1'],
    )).single;
    expect(product['nombre'], 'Producto local');
    expect(await database.query('producto_variantes_catalogo'), hasLength(1));
    expect(await database.query('producto_familia_ejes'), hasLength(1));
  });
}

Future<void> _insertCompleteProduct(Database database) async {
  final categoryId = await database.insert('categorias', {
    'nombre': 'Categoria de prueba',
    'actualizado_en': '2026-08-04T00:00:00Z',
  });
  await database.insert('categoria_atributos', {
    'id': 'attribute-1',
    'categoria_id': categoryId,
    'nombre': 'Color',
    'clave': 'color',
    'tipo_dato': 'lista_unica',
    'nivel_captura': 'familia',
    'puede_ser_eje': 1,
    'actualizado_en': '2026-08-04T00:00:00Z',
  });
  await database.insert('categoria_atributo_opciones', {
    'id': 'option-1',
    'categoria_atributo_id': 'attribute-1',
    'etiqueta': 'Rojo',
    'codigo': 'RED',
  });
  await database.insert('productos', {
    'id': 'product-1',
    'codigo': 'FAM-001',
    'nombre': 'Producto local',
    'descripcion': '',
    'empresa': 'DINA',
    'marca': 'DINA',
    'categoria': 'Categoria de prueba',
    'subcategoria': '',
    'tipo_registro': 'simple',
    'atributos_json': jsonEncode({'Color': 'Rojo'}),
    'variantes_json': jsonEncode([
      {
        'id': 'variant-1',
        'sku': 'SKU-001',
        'codigo_proveedor': 'PROV-1',
        'nombre_corto': 'Producto',
        'atributos': const [],
        'activa': true,
      },
    ]),
    'presentaciones_json': jsonEncode([
      {'nombre': 'Unidad', 'unidad': 'UND'},
    ]),
    'venta_logistica_json': '{}',
    'precios_configurados_json': '{}',
    'imagenes_configuradas_json': '{}',
    'precios_json': jsonEncode([
      {'presentacion': 'Unidad', 'valor': 10.0, 'variante_id': 'variant-1'},
    ]),
    'unidad_venta': 'Unidad',
    'precio': 10.0,
    'sin_precio': 0,
    'activo': 1,
    'imagen_path': r'D:\images\product-1.jpg',
    'imagenes_json': jsonEncode([r'D:\images\product-1.jpg']),
    'creado_en': '2026-08-04T00:00:00Z',
  });
  await database.insert('producto_variantes_catalogo', {
    'id': 'variant-1',
    'producto_id': 'product-1',
    'sku': 'SKU-001',
    'codigo_proveedor': 'PROV-1',
    'nombre_corto': 'Producto',
    'estado': 1,
  });
  await database.insert('producto_familia_ejes', {
    'producto_id': 'product-1',
    'categoria_atributo_id': 'attribute-1',
    'orden': 0,
  });
  await database.insert('producto_atributos', {
    'id': 'product-attribute-1',
    'categoria_atributo_id': 'attribute-1',
    'producto_id': 'product-1',
    'tipo_valor': 'lista_unica',
    'valor_texto': 'Rojo',
    'actualizado_en': '2026-08-04T00:00:00Z',
  });
  await database.insert('producto_atributo_opciones', {
    'producto_atributo_id': 'product-attribute-1',
    'categoria_atributo_id': 'attribute-1',
    'opcion_id': 'option-1',
  });
  await database.update('sync_file_queue', {
    'status': 'ready',
    'object_key': 'files/file-1/content',
  }, where: "owner_type = 'PRODUCT' AND owner_id = 'product-1'");
}
