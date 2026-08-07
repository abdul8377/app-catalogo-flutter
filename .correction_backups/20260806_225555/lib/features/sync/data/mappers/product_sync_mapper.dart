import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class ProductSyncMapper {
  const ProductSyncMapper();

  Future<Map<String, Object?>> exportProductAggregate(
    DatabaseExecutor database, {
    required String productId,
    required String operation,
  }) async {
    if (operation == 'DELETE') return const {};
    final products = await database.query(
      'productos',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (products.isEmpty) return const {};
    final product = products.single;
    final variantRows = await database.query(
      'producto_variantes_catalogo',
      where: 'producto_id = ?',
      whereArgs: [productId],
      orderBy: 'sku',
    );
    final variantIds = variantRows.map((row) => row['id']).toList();
    final familyAxes = await database.query(
      'producto_familia_ejes',
      where: 'producto_id = ?',
      whereArgs: [productId],
      orderBy: 'orden',
    );
    final attributeRows = <Map<String, Object?>>[
      ...await database.query(
        'producto_atributos',
        where: 'producto_id = ?',
        whereArgs: [productId],
      ),
    ];
    if (variantIds.isNotEmpty) {
      final placeholders = List.filled(variantIds.length, '?').join(',');
      attributeRows.addAll(
        await database.query(
          'producto_atributos',
          where: 'variante_id IN ($placeholders)',
          whereArgs: variantIds,
        ),
      );
    }
    final attributeIds = attributeRows.map((row) => row['id']).toList();
    final optionRows = attributeIds.isEmpty
        ? <Map<String, Object?>>[]
        : await database.query(
            'producto_atributo_opciones',
            where:
                'producto_atributo_id IN '
                '(${List.filled(attributeIds.length, '?').join(',')})',
            whereArgs: attributeIds,
          );

    final localVariants = _decodeList(product['variantes_json']);
    final variantsById = <String, Map<String, Object?>>{
      for (final variant in localVariants)
        if ((variant['id']?.toString() ?? '').isNotEmpty)
          variant['id'].toString(): variant,
    };
    final variants = variantRows.map((row) {
      final local = variantsById[row['id']] ?? const <String, Object?>{};
      return <String, Object?>{
        'id': row['id'],
        'sku': row['sku'],
        'supplierCode': row['codigo_proveedor'] ?? '',
        'shortName': row['nombre_corto'] ?? '',
        'status': (row['estado'] as num? ?? 1).toInt() == 1
            ? 'ACTIVE'
            : 'INACTIVE',
        'attributes': _variantAttributes(local['atributos']),
      };
    }).toList();
    if (variants.isEmpty) {
      variants.add({
        'id': '$productId:single',
        'sku': product['codigo'] ?? productId,
        'supplierCode': '',
        'shortName': product['nombre'] ?? '',
        'status': (product['activo'] as num? ?? 1).toInt() == 1
            ? 'ACTIVE'
            : 'INACTIVE',
        'attributes': const <String, Object?>{},
      });
    }

    final presentations = _decodeList(product['presentaciones_json'])
        .map(
          (row) => <String, Object?>{
            'id': row['id'] ?? row['presentacion_id'] ?? '',
            'sku': row['sku'] ?? '',
            'name': row['name'] ?? row['nombre'] ?? 'Unidad',
            'equivalence': row['equivalence'] ?? row['equivalencia'] ?? 1,
            'baseUnit': row['baseUnit'] ?? row['unidad'] ?? 'UND',
            'minimumSale': row['minimumSale'] ?? row['venta_minima'] ?? 1,
            'status': row['status'] ?? 'ACTIVE',
          },
        )
        .toList();
    final prices = _exportPrices(
      _decodeList(product['precios_json']),
      _decodeMap(product['precios_configurados_json']),
      variantsById,
    );
    final images = await _exportImages(database, productId, product);

    return {
      'productId': productId,
      'code': product['codigo'] ?? '',
      'name': product['nombre'] ?? '',
      'description': product['descripcion'] ?? '',
      'company': product['empresa'] ?? '',
      'companyId': await _syncIdByName(
        database,
        'empresas',
        product['empresa'],
      ),
      'brand': product['marca'] ?? '',
      'brandId': await _syncIdByName(database, 'marcas', product['marca']),
      'category': product['categoria'] ?? '',
      'categoryId': await _syncIdByName(
        database,
        'categorias',
        product['categoria'],
      ),
      'subcategory': product['subcategoria'] ?? '',
      'subcategoryId': await _syncIdByName(
        database,
        'categorias',
        product['subcategoria'],
      ),
      'productType': _toRemoteProductType(
        product['tipo_registro']?.toString() ?? '',
      ),
      'status': (product['activo'] as num? ?? 1).toInt() == 1
          ? 'ACTIVE'
          : 'INACTIVE',
      'attributes': _decodeMap(product['atributos_json']),
      'variants': variants,
      'presentations': presentations,
      'prices': prices,
      'images': images,
      'familyAxes': familyAxes,
      'attributeValues': attributeRows,
      'attributeOptions': optionRows,
    };
  }

  Future<void> applyProductAggregate(
    DatabaseExecutor database, {
    required String productId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    if (operation == 'DELETE') {
      await database.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [productId],
      );
      return;
    }
    final aggregate = payload['product'] is Map
        ? Map<String, Object?>.from(payload['product'] as Map)
        : Map<String, Object?>.from(payload);
    final code = aggregate['code']?.toString().trim() ?? '';
    final name = aggregate['name']?.toString().trim() ?? '';
    final variants = _asMaps(aggregate['variants']);
    final presentations = _asMaps(aggregate['presentations']);
    final prices = _asMaps(aggregate['prices']);
    final images = _asMaps(aggregate['images']);
    final attributes = aggregate['attributes'];
    if (code.isEmpty || name.isEmpty) {
      throw const FormatException(
        'El agregado PRODUCT no contiene codigo y nombre.',
      );
    }
    if (variants.isEmpty) {
      throw const FormatException(
        'El agregado PRODUCT debe contener al menos una variante.',
      );
    }
    if (attributes is! Map) {
      throw const FormatException('PRODUCT.attributes debe ser un objeto.');
    }
    final skus = <String>{};
    for (final variant in variants) {
      final sku = variant['sku']?.toString().trim().toUpperCase() ?? '';
      if (sku.isEmpty || !skus.add(sku)) {
        throw const FormatException(
          'Las variantes de PRODUCT requieren SKU unicos.',
        );
      }
    }
    for (final price in prices) {
      final sku = price['sku']?.toString().trim().toUpperCase() ?? '';
      if (sku.isNotEmpty && !skus.contains(sku)) {
        throw FormatException('Un precio referencia el SKU inexistente $sku.');
      }
      final value = price['price'] ?? price['valor'];
      if (value != null && value is! num) {
        throw const FormatException('El precio de PRODUCT no es numerico.');
      }
    }

    final existing = await database.query(
      'productos',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    final existingRow = existing.firstOrNull;
    final localVariants = variants.map(_localVariant).toList();
    final localPresentations = presentations
        .map(
          (row) => <String, Object?>{
            'nombre': row['name'] ?? row['nombre'] ?? 'Unidad',
            'unidad': row['baseUnit'] ?? row['unidad'] ?? 'UND',
          },
        )
        .toList();
    final localPrices = prices.map((row) {
      final sku = row['sku']?.toString() ?? '';
      final variant = variants
          .where((item) => item['sku']?.toString() == sku)
          .firstOrNull;
      return <String, Object?>{
        'presentacion': row['presentation'] ?? row['presentacion'] ?? 'Unidad',
        'valor': row['price'] ?? row['valor'],
        'lista_precio_id': row['priceListId'] ?? row['lista_precio_id'] ?? '',
        'variante_id': variant?['id'] ?? '',
        'presentacion_id': row['presentationId'] ?? '',
        'configuracion': row['configuration'] ?? 'precio_fijo',
      };
    }).toList();
    final firstPrice = localPrices
        .map((row) => row['valor'])
        .whereType<num>()
        .firstOrNull;
    final values = <String, Object?>{
      'id': productId,
      'codigo': code,
      'nombre': name,
      'descripcion': aggregate['description']?.toString() ?? '',
      'empresa': aggregate['company']?.toString() ?? '',
      'marca': aggregate['brand']?.toString() ?? '',
      'categoria': aggregate['category']?.toString() ?? '',
      'subcategoria': aggregate['subcategory']?.toString() ?? '',
      'tipo_registro': _toLocalProductType(
        aggregate['productType']?.toString() ?? 'SINGLE',
      ),
      'atributos_json': jsonEncode(Map<String, Object?>.from(attributes)),
      'variantes_json': jsonEncode(localVariants),
      'presentaciones_json': jsonEncode(localPresentations),
      'venta_logistica_json':
          existingRow?['venta_logistica_json']?.toString() ?? '{}',
      'precios_configurados_json': jsonEncode({'prices': prices}),
      'imagenes_configuradas_json': jsonEncode({'remote_images': images}),
      'precios_json': jsonEncode(localPrices),
      'unidad_venta': localPresentations.isEmpty
          ? 'UND'
          : localPresentations.first['nombre'],
      'precio': firstPrice?.toDouble(),
      'sin_precio': firstPrice == null ? 1 : 0,
      'activo': _toLocalActive(aggregate['status']?.toString()),
      'imagen_path': existingRow?['imagen_path'],
      'imagenes_json': existingRow?['imagenes_json']?.toString() ?? '[]',
      'creado_en':
          existingRow?['creado_en']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
    };

    if (existing.isEmpty) {
      await database.insert('productos', values);
    } else {
      values.remove('id');
      await database.update(
        'productos',
        values,
        where: 'id = ?',
        whereArgs: [productId],
      );
    }

    final oldVariants = await database.query(
      'producto_variantes_catalogo',
      columns: const ['id'],
      where: 'producto_id = ?',
      whereArgs: [productId],
    );
    final oldVariantIds = oldVariants.map((row) => row['id']).toList();
    if (oldVariantIds.isNotEmpty) {
      await database.delete(
        'producto_atributos',
        where:
            'variante_id IN '
            '(${List.filled(oldVariantIds.length, '?').join(',')})',
        whereArgs: oldVariantIds,
      );
    }
    await database.delete(
      'producto_atributos',
      where: 'producto_id = ?',
      whereArgs: [productId],
    );
    await database.delete(
      'producto_familia_ejes',
      where: 'producto_id = ?',
      whereArgs: [productId],
    );
    await database.delete(
      'producto_variantes_catalogo',
      where: 'producto_id = ?',
      whereArgs: [productId],
    );

    for (final variant in variants) {
      final sku = variant['sku']!.toString().trim().toUpperCase();
      await database.insert('producto_variantes_catalogo', {
        'id': _variantId(productId, variant),
        'producto_id': productId,
        'sku': sku,
        'codigo_proveedor':
            variant['supplierCode'] ?? variant['codigo_proveedor'] ?? '',
        'nombre_corto': variant['shortName'] ?? variant['nombre_corto'] ?? '',
        'estado': _toLocalActive(variant['status']?.toString()),
      });
    }

    await _restoreProjectionRows(
      database,
      productId: productId,
      aggregate: aggregate,
    );
  }

  Future<void> _restoreProjectionRows(
    DatabaseExecutor database, {
    required String productId,
    required Map<String, Object?> aggregate,
  }) async {
    for (final axis in _asMaps(aggregate['familyAxes'])) {
      final attributeId =
          axis['categoria_atributo_id']?.toString() ??
          axis['categoryAttributeId']?.toString() ??
          '';
      if (attributeId.isEmpty) continue;
      await database.insert('producto_familia_ejes', {
        'producto_id': productId,
        'categoria_atributo_id': attributeId,
        'orden': (axis['orden'] as num? ?? axis['order'] as num? ?? 0).toInt(),
      });
    }

    final restoredAttributeIds = <String>{};
    for (final row in _asMaps(aggregate['attributeValues'])) {
      final id = row['id']?.toString() ?? '';
      final definitionId =
          row['categoria_atributo_id']?.toString() ??
          row['categoryAttributeId']?.toString() ??
          '';
      if (id.isEmpty || definitionId.isEmpty) continue;
      final values = Map<String, Object?>.from(row)
        ..['id'] = id
        ..['categoria_atributo_id'] = definitionId;
      values.remove('categoryAttributeId');
      if (values['producto_id'] != null) values['producto_id'] = productId;
      final columns = (await database.rawQuery(
        'PRAGMA table_info(producto_atributos)',
      )).map((column) => column['name']).toSet();
      values.removeWhere((key, _) => !columns.contains(key));
      await database.insert('producto_atributos', values);
      restoredAttributeIds.add(id);
    }
    for (final row in _asMaps(aggregate['attributeOptions'])) {
      final attributeId = row['producto_atributo_id']?.toString() ?? '';
      if (!restoredAttributeIds.contains(attributeId)) continue;
      await database.insert('producto_atributo_opciones', row);
    }
  }

  Future<List<Map<String, Object?>>> _exportImages(
    DatabaseExecutor database,
    String productId,
    Map<String, Object?> product,
  ) async {
    final paths = <String>{};
    final primary = product['imagen_path']?.toString() ?? '';
    if (primary.isNotEmpty) paths.add(primary);
    for (final value in _decodeListValues(product['imagenes_json'])) {
      if (value.toString().trim().isNotEmpty) paths.add(value.toString());
    }
    _collectPaths(_decodeMap(product['imagenes_configuradas_json']), paths);
    final result = <Map<String, Object?>>[];
    for (final path in paths) {
      final files = await database.query(
        'sync_file_queue',
        columns: const ['object_key'],
        where:
            'owner_type = ? AND owner_id = ? AND local_path = ? '
            "AND status IN ('ready', 'downloaded')",
        whereArgs: ['PRODUCT', productId, path],
        limit: 1,
      );
      if (files.isEmpty) continue;
      final storageKey = files.single['object_key']?.toString() ?? '';
      if (storageKey.isEmpty) continue;
      result.add({
        'sku': '',
        'storageKey': storageKey,
        'type': 'PRODUCT',
        'primary': path == primary,
      });
    }
    return result;
  }

  List<Map<String, Object?>> _exportPrices(
    List<Map<String, Object?>> localPrices,
    Map<String, Object?> configured,
    Map<String, Map<String, Object?>> variantsById,
  ) {
    final rows = localPrices.isNotEmpty
        ? localPrices
        : _asMaps(configured['prices']);
    return rows.map((row) {
      final variantId = row['variante_id']?.toString() ?? '';
      return <String, Object?>{
        'sku': variantsById[variantId]?['sku'] ?? row['sku'] ?? '',
        'priceList': row['lista_precio_nombre'] ?? 'General',
        'priceListId': row['lista_precio_id'] ?? '',
        'presentation': row['presentacion'] ?? 'Unidad',
        'presentationId': row['presentacion_id'] ?? '',
        'currency': row['moneda'] ?? 'PEN',
        'taxRate': row['impuesto'] ?? 18,
        'price': row['valor'] ?? row['price'] ?? 0,
        'quoteRequired': row['requiere_cotizacion'] ?? false,
        'configuration': row['configuracion'] ?? 'precio_fijo',
      };
    }).toList();
  }

  Map<String, Object?> _localVariant(Map<String, Object?> row) => {
    'id': row['id'],
    'sku': row['sku'],
    'codigo_proveedor': row['supplierCode'] ?? row['codigo_proveedor'] ?? '',
    'nombre_corto': row['shortName'] ?? row['nombre_corto'] ?? '',
    'atributos': _localVariantAttributes(row['attributes']),
    'activa': _toLocalActive(row['status']?.toString()) == 1,
    'imagen_path': null,
  };

  List<Map<String, Object?>> _localVariantAttributes(Object? value) {
    if (value is List) return _asMaps(value);
    if (value is! Map) return const [];
    return value.entries.map((entry) {
      final details = entry.value is Map
          ? Map<String, Object?>.from(entry.value as Map)
          : <String, Object?>{'value': entry.value};
      return <String, Object?>{
        'nombre': entry.key.toString(),
        'valor': details['value'] ?? details['valor'] ?? '',
        'unidad': details['unit'] ?? details['unidad'] ?? '',
        'valor_normalizado':
            details['normalizedValue'] ?? details['valor_normalizado'],
        'valor_maximo': details['maximumValue'] ?? details['valor_maximo'],
        'valores': details['values'] ?? details['valores'] ?? const [],
      };
    }).toList();
  }

  Map<String, Object?> _variantAttributes(Object? value) {
    final result = <String, Object?>{};
    for (final row in _asMaps(value)) {
      final name = row['nombre']?.toString() ?? row['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      result[name] = {
        'value': row['valor'] ?? row['value'] ?? '',
        'unit': row['unidad'] ?? row['unit'] ?? '',
        'normalizedValue': row['valor_normalizado'] ?? row['normalizedValue'],
        'maximumValue': row['valor_maximo'] ?? row['maximumValue'],
        'values': row['valores'] ?? row['values'] ?? const [],
      };
    }
    return result;
  }

  String _variantId(String productId, Map<String, Object?> variant) {
    final id = variant['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    return '$productId:${variant['sku'].toString().trim().toUpperCase()}';
  }

  Future<String> _syncIdByName(
    DatabaseExecutor database,
    String table,
    Object? value,
  ) async {
    final name = value?.toString().trim() ?? '';
    if (name.isEmpty) return '';
    final rows = await database.query(
      table,
      columns: const ['sync_id'],
      where: 'LOWER(TRIM(nombre)) = LOWER(TRIM(?))',
      whereArgs: [name],
      limit: 1,
    );
    return rows.firstOrNull?['sync_id']?.toString() ?? '';
  }

  String _toRemoteProductType(String value) => switch (value.toLowerCase()) {
    'lista' => 'LIST',
    'matriz' => 'MATRIX',
    _ => 'SINGLE',
  };

  String _toLocalProductType(String value) => switch (value.toUpperCase()) {
    'LIST' => 'lista',
    'MATRIX' => 'matriz',
    _ => 'simple',
  };

  int _toLocalActive(String? value) => switch (value?.toUpperCase()) {
    'INACTIVE' || 'DELETED' => 0,
    _ => 1,
  };

  Map<String, Object?> _decodeMap(Object? value) {
    final decoded = _decode(value);
    return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
  }

  List<Map<String, Object?>> _decodeList(Object? value) =>
      _asMaps(_decode(value));

  List<Object?> _decodeListValues(Object? value) {
    final decoded = _decode(value);
    return decoded is List ? List<Object?>.from(decoded) : const [];
  }

  Object? _decode(Object? value) {
    if (value is! String) return value;
    if (value.trim().isEmpty) return null;
    return jsonDecode(value);
  }

  List<Map<String, Object?>> _asMaps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((row) => Map<String, Object?>.from(row))
            .toList()
      : const [];

  void _collectPaths(Object? value, Set<String> paths) {
    if (value is String) {
      if (value.trim().isNotEmpty) paths.add(value);
      return;
    }
    if (value is List) {
      for (final item in value) {
        _collectPaths(item, paths);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (key.contains('path') || key.contains('image')) {
          _collectPaths(entry.value, paths);
        }
      }
    }
  }
}
