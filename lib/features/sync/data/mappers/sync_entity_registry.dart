import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'product_sync_mapper.dart';

class SyncEntityRegistry {
  const SyncEntityRegistry([this._productMapper = const ProductSyncMapper()]);

  final ProductSyncMapper _productMapper;

  static const initialSnapshotOrder = <String>[
    'COMPANY',
    'BRAND',
    'CATEGORY',
    'BRAND_CATEGORY',
    'MEASUREMENT_UNIT',
    'CATEGORY_ATTRIBUTE',
    'CATEGORY_ATTRIBUTE_OPTION',
    'CATEGORY_ATTRIBUTE_UNIT',
    'LEGACY_ATTRIBUTE_DEFINITION',
    'PRICE_LIST',
    'PRODUCT',
    'CLIENT',
    'ORDER_SHEET',
    'ORDER',
    'ORDER_ITEM',
    'QUOTE',
    'QUOTE_ITEM',
    'PREPARATION',
    'PREPARATION_STOCK_MOVEMENT',
    'ORDER_LOAD',
    'ORDER_HISTORY',
    'ORDER_SHEET_HISTORY',
  ];

  Future<Map<String, Object?>> exportEntity(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required String operation,
  }) async {
    if (operation == 'DELETE') return const {};
    if (entityType == 'PRODUCT') {
      return _productMapper.exportProductAggregate(
        database,
        productId: entityId,
        operation: operation,
      );
    }
    final spec = _spec(entityType);
    final rows = await database.query(
      spec.table,
      where: spec.whereIdentity,
      whereArgs: spec.identityArgs(entityId),
      limit: 1,
    );
    if (rows.isEmpty) return const {};
    final payload = Map<String, Object?>.from(rows.single);
    final localFilePath = switch (entityType) {
      'CLIENT' => payload['foto_ubicacion_path']?.toString(),
      'QUOTE' => payload['pdf_path']?.toString(),
      _ => null,
    };
    payload.remove('sync_id');
    for (final localOnly in const [
      'imagen_path',
      'imagenes_json',
      'imagenes_configuradas_json',
      'foto_ubicacion_path',
      'pdf_path',
    ]) {
      payload.remove(localOnly);
    }
    if (spec.identityColumn == 'sync_id') payload['id'] = entityId;
    if (localFilePath != null && localFilePath.isNotEmpty) {
      final fileRows = await database.query(
        'sync_file_queue',
        columns: const ['object_key'],
        where:
            'owner_type = ? AND owner_id = ? AND local_path = ? '
            "AND status = 'ready'",
        whereArgs: [entityType, entityId, localFilePath],
        limit: 1,
      );
      final storageKey = fileRows.firstOrNull?['object_key']?.toString() ?? '';
      if (storageKey.isNotEmpty) {
        payload[entityType == 'CLIENT'
                ? 'locationPhotoStorageKey'
                : 'pdfStorageKey'] =
            storageKey;
      }
    }
    for (final reference in spec.integerReferences.entries) {
      final value = payload[reference.key];
      if (value == null) continue;
      final parent = await database.query(
        reference.value,
        columns: const ['sync_id'],
        where: 'id = ?',
        whereArgs: [value],
        limit: 1,
      );
      if (parent.isNotEmpty) payload[reference.key] = parent.single['sync_id'];
    }
    return payload;
  }

  Future<void> applyRemote(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    if (entityType == 'PRODUCT') {
      await _productMapper.applyProductAggregate(
        database,
        productId: entityId,
        operation: operation,
        payload: payload,
      );
      return;
    }
    final spec = _spec(entityType);
    if (operation == 'DELETE') {
      await database.delete(
        spec.table,
        where: spec.whereIdentity,
        whereArgs: spec.identityArgs(entityId),
      );
      return;
    }

    final source = payload['data'] is Map
        ? Map<String, Object?>.from(payload['data'] as Map)
        : Map<String, Object?>.from(payload);
    final normalized = <String, Object?>{};
    for (final entry in source.entries) {
      normalized[_snakeCase(entry.key)] = entry.value;
    }
    _applyAliases(entityType, normalized);

    final columns = (await database.rawQuery(
      'PRAGMA table_info(${spec.table})',
    )).map((row) => row['name'] as String).toSet();
    final values = <String, Object?>{
      for (final entry in normalized.entries)
        if (columns.contains(entry.key)) entry.key: _sqliteValue(entry.value),
    };
    values.remove('sync_id');

    for (final reference in spec.integerReferences.entries) {
      final remoteId = values[reference.key];
      if (remoteId == null || remoteId.toString().isEmpty) continue;
      final parent = await database.query(
        reference.value,
        columns: const ['id'],
        where: 'sync_id = ?',
        whereArgs: [remoteId.toString()],
        limit: 1,
      );
      if (parent.isEmpty) {
        throw StateError(
          'Falta ${reference.value} $remoteId para aplicar $entityType.',
        );
      }
      values[reference.key] = parent.single['id'];
    }

    if (entityType == 'MEASUREMENT_UNIT') {
      await _applyRemoteMeasurementUnit(
        database,
        entityId: entityId,
        values: values,
      );
      return;
    }

    if (await _mergeRemoteRelationalMasterByNaturalKey(
      database,
      entityType: entityType,
      entityId: entityId,
      values: values,
    )) {
      return;
    }

    if (spec.identityColumn == 'sync_id') {
      values['sync_id'] = entityId;
      values.remove('id');
    } else {
      values['id'] = entityId;
    }

    final existing = await database.query(
      spec.table,
      columns: const ['rowid'],
      where: spec.whereIdentity,
      whereArgs: spec.identityArgs(entityId),
      limit: 1,
    );
    if (existing.isNotEmpty) {
      values.remove('id');
      values.remove('sync_id');
      if (values.isNotEmpty) {
        await database.update(
          spec.table,
          values,
          where: spec.whereIdentity,
          whereArgs: spec.identityArgs(entityId),
        );
      }
      return;
    }

    await database.insert(spec.table, values);
  }

  Future<List<String>> listEntityIdentities(
    DatabaseExecutor database,
    String entityType,
  ) async {
    if (entityType == 'PRODUCT') {
      return (await database.query('productos', columns: const ['id']))
          .map((row) => row['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    final spec = _spec(entityType);
    final rows = await database.query(
      spec.table,
      columns: [spec.identityColumn],
    );
    return rows
        .map((row) => row[spec.identityColumn]?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> pruneMissingRemoteEntities(DatabaseExecutor database) async {
    for (final entityType in initialSnapshotOrder.reversed) {
      final table = entityType == 'PRODUCT'
          ? 'productos'
          : _spec(entityType).table;
      final identityColumn = entityType == 'PRODUCT'
          ? 'id'
          : _spec(entityType).identityColumn;
      await database.rawDelete(
        '''
        DELETE FROM $table
        WHERE $identityColumn NOT IN (
          SELECT entity_id
          FROM sync_entity_state
          WHERE entity_type = ?
        )
      ''',
        [entityType],
      );
    }
  }

  _SyncEntitySpec _spec(String entityType) {
    final spec = _specs[entityType];
    if (spec == null) {
      throw UnsupportedError(
        'Entidad de sincronización desconocida: $entityType',
      );
    }
    return spec;
  }

  Future<bool> _mergeRemoteRelationalMasterByNaturalKey(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required Map<String, Object?> values,
  }) async {
    if (!const {
      'COMPANY',
      'BRAND',
      'CATEGORY',
      'BRAND_CATEGORY',
    }.contains(entityType)) {
      return false;
    }

    final spec = _spec(entityType);
    final remoteMatches = await database.query(
      spec.table,
      columns: const ['sync_id'],
      where: 'sync_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    if (remoteMatches.isNotEmpty) {
      return false;
    }

    String where;
    List<Object?> whereArgs;
    switch (entityType) {
      case 'COMPANY':
        final name = values['nombre']?.toString().trim() ?? '';
        if (name.isEmpty) {
          return false;
        }
        where = 'nombre = ? COLLATE NOCASE';
        whereArgs = [name];
      case 'BRAND':
        final companyId = values['empresa_id'];
        final name = values['nombre']?.toString().trim() ?? '';
        if (companyId == null || name.isEmpty) {
          return false;
        }
        where = 'empresa_id = ? AND nombre = ? COLLATE NOCASE';
        whereArgs = [companyId, name];
      case 'CATEGORY':
        final parentId = values['categoria_padre_id'];
        final name = values['nombre']?.toString().trim() ?? '';
        if (name.isEmpty) {
          return false;
        }
        if (parentId == null) {
          where = 'categoria_padre_id IS NULL AND nombre = ? COLLATE NOCASE';
          whereArgs = [name];
        } else {
          where = 'categoria_padre_id = ? AND nombre = ? COLLATE NOCASE';
          whereArgs = [parentId, name];
        }
      case 'BRAND_CATEGORY':
        final brandId = values['marca_id'];
        final categoryId = values['categoria_id'];
        if (brandId == null || categoryId == null) {
          return false;
        }
        where = 'marca_id = ? AND categoria_id = ?';
        whereArgs = [brandId, categoryId];
      default:
        return false;
    }

    final naturalMatches = await database.query(
      spec.table,
      columns: const ['sync_id'],
      where: where,
      whereArgs: whereArgs,
      limit: 2,
    );
    if (naturalMatches.isEmpty) {
      return false;
    }
    if (naturalMatches.length > 1) {
      throw StateError(
        'Se encontraron varias filas locales para la clave natural de '
        '$entityType.',
      );
    }

    final currentSyncId =
        naturalMatches.single['sync_id']?.toString().trim() ?? '';
    if (currentSyncId.isNotEmpty && currentSyncId != entityId) {
      final pending = await database.query(
        'sync_queue',
        columns: const ['id'],
        where:
            'entidad = ? AND entidad_id = ? '
            "AND estado IN ('pending', 'retry', 'sending', 'conflict')",
        whereArgs: [entityType, currentSyncId],
        limit: 1,
      );
      if (pending.isNotEmpty) {
        throw StateError(
          'No se puede adoptar la identidad remota de $entityType porque '
          'la fila local $currentSyncId tiene cambios pendientes.',
        );
      }
    }

    final mergedValues = Map<String, Object?>.from(values)
      ..remove('id')
      ..['sync_id'] = entityId;
    await database.update(
      spec.table,
      mergedValues,
      where: where,
      whereArgs: whereArgs,
    );
    return true;
  }

  Future<void> _applyRemoteMeasurementUnit(
    DatabaseExecutor database, {
    required String entityId,
    required Map<String, Object?> values,
  }) async {
    final unitValues = Map<String, Object?>.from(values)
      ..remove('id')
      ..['sync_id'] = entityId;

    final remoteMatches = await database.query(
      'unidades_medida',
      columns: const ['id'],
      where: 'sync_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    if (remoteMatches.isNotEmpty) {
      await database.update(
        'unidades_medida',
        unitValues,
        where: 'id = ?',
        whereArgs: [remoteMatches.single['id']],
      );
      return;
    }

    final code = unitValues['codigo']?.toString().trim() ?? '';
    if (code.isNotEmpty) {
      final naturalMatches = await database.query(
        'unidades_medida',
        columns: const ['id', 'sync_id'],
        where: 'codigo = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (naturalMatches.isNotEmpty) {
        final naturalMatch = naturalMatches.single;
        final currentSyncId = naturalMatch['sync_id']?.toString().trim() ?? '';
        if (currentSyncId.isNotEmpty && currentSyncId != entityId) {
          throw StateError(
            'La unidad $code ya está vinculada con $currentSyncId '
            'y no puede vincularse con $entityId.',
          );
        }
        await database.update(
          'unidades_medida',
          unitValues,
          where: 'id = ?',
          whereArgs: [naturalMatch['id']],
        );
        return;
      }
    }

    unitValues['id'] = entityId;
    await database.insert('unidades_medida', unitValues);
  }

  Object? _sqliteValue(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is List || value is Map) return jsonEncode(value);
    return value;
  }

  String _snakeCase(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toLowerCase();

  void _applyAliases(String entityType, Map<String, Object?> values) {
    const commonAliases = {
      'code': 'codigo',
      'name': 'nombre',
      'description': 'descripcion',
      'active': 'activo',
      'status': 'estado',
      'created_at': 'creado_en',
      'updated_at': 'actualizado_en',
      'company_id': 'empresa_id',
      'category_id': 'categoria_id',
      'parent_category_id': 'categoria_padre_id',
      'brand_id': 'marca_id',
      'order_id': 'pedido_id',
      'order_item_id': 'pedido_item_id',
      'order_sheet_id': 'hoja_id',
      'client_id': 'cliente_id',
      'product_id': 'producto_id',
      'quote_id': 'cotizacion_id',
      'category_attribute_id': 'categoria_atributo_id',
      'measurement_unit_id': 'unidad_medida_id',
      'product_attribute_id': 'producto_atributo_id',
      'option_id': 'opcion_id',
    };
    const productAliases = {
      'company': 'empresa',
      'brand': 'marca',
      'category': 'categoria',
      'subcategory': 'subcategoria',
      'record_type': 'tipo_registro',
      'sale_unit': 'unidad_venta',
      'price': 'precio',
      'no_price': 'sin_precio',
    };
    const priceListAliases = {
      'active': 'estado',
      'currency': 'moneda',
      'includes_tax': 'incluye_igv',
      'tax_rate': 'igv_porcentaje',
    };
    const clientAliases = {
      'phone': 'telefono',
      'customer_type': 'tipo',
      'delivery_type': 'tipo_entrega',
      'address': 'direccion',
      'reference': 'referencia',
      'notes': 'observaciones',
      'location_photo_path': 'foto_ubicacion_path',
    };
    const orderAliases = {
      'seller': 'vendedor',
      'known_subtotal': 'subtotal_conocido',
      'partial_total': 'total_parcial',
      'synced': 'sincronizado',
    };
    const orderSheetAliases = {
      'seller': 'vendedor',
      'closed_at': 'fecha_cierre',
      'reference': 'referencia',
      'notes': 'observacion',
      'synced': 'sincronizado',
      'closed_by': 'usuario_cierre',
    };
    const orderItemAliases = {
      'presentation': 'presentacion',
      'equivalence': 'equivalencia',
      'quantity': 'cantidad',
      'base_unit_factor': 'factor_unidad_base',
      'base_unit': 'unidad_base',
      'unit_price': 'precio_unitario',
      'variant_id': 'variante_id',
      'variant_sku': 'variante_sku',
      'variant_name': 'variante_nombre',
      'variant_attributes_json': 'atributos_variante_json',
      'presentation_id': 'presentacion_id',
      'price_list_id': 'precio_lista_id',
      'price_list_name': 'precio_lista_nombre',
      'price_configuration': 'precio_configuracion',
      'image_path': 'imagen_path',
    };
    const quoteAliases = {
      'base_code': 'codigo_base',
      'global_discount': 'descuento_global',
      'global_discount_type': 'tipo_descuento_global',
      'global_discount_percentage': 'descuento_global_porcentaje',
      'global_discount_amount': 'descuento_global_monto',
      'validity_days': 'vigencia_dias',
      'terms': 'condiciones',
      'notes': 'observaciones',
    };
    const quoteItemAliases = {
      'presentation': 'presentacion',
      'quantity': 'cantidad',
      'quoted_price': 'precio_cotizacion',
      'discount': 'descuento',
      'discount_type': 'tipo_descuento',
      'final_price': 'precio_final',
    };

    final aliases = <String, String>{
      ...commonAliases,
      if (entityType == 'PRODUCT') ...productAliases,
      if (entityType == 'PRICE_LIST') ...priceListAliases,
      if (entityType == 'CLIENT') ...clientAliases,
      if (entityType == 'ORDER') ...orderAliases,
      if (entityType == 'ORDER_SHEET') ...orderSheetAliases,
      if (entityType == 'ORDER_ITEM') ...orderItemAliases,
      if (entityType == 'QUOTE') ...quoteAliases,
      if (entityType == 'QUOTE_ITEM') ...quoteItemAliases,
    };
    for (final entry in aliases.entries) {
      if (values.containsKey(entry.key) && !values.containsKey(entry.value)) {
        values[entry.value] = values[entry.key];
      }
    }
  }
}

class _SyncEntitySpec {
  const _SyncEntitySpec({
    required this.table,
    this.identityColumn = 'id',
    this.integerReferences = const {},
  });

  final String table;
  final String identityColumn;
  final Map<String, String> integerReferences;

  String get whereIdentity => '$identityColumn = ?';

  List<Object?> identityArgs(String entityId) => [entityId];
}

const _specs = <String, _SyncEntitySpec>{
  'COMPANY': _SyncEntitySpec(table: 'empresas', identityColumn: 'sync_id'),
  'BRAND': _SyncEntitySpec(
    table: 'marcas',
    identityColumn: 'sync_id',
    integerReferences: {'empresa_id': 'empresas'},
  ),
  'CATEGORY': _SyncEntitySpec(
    table: 'categorias',
    identityColumn: 'sync_id',
    integerReferences: {'categoria_padre_id': 'categorias'},
  ),
  'BRAND_CATEGORY': _SyncEntitySpec(
    table: 'marca_categorias',
    identityColumn: 'sync_id',
    integerReferences: {'marca_id': 'marcas', 'categoria_id': 'categorias'},
  ),
  'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
  ),
  'CATEGORY_ATTRIBUTE': _SyncEntitySpec(
    table: 'categoria_atributos',
    integerReferences: {'categoria_id': 'categorias'},
  ),
  'CATEGORY_ATTRIBUTE_OPTION': _SyncEntitySpec(
    table: 'categoria_atributo_opciones',
  ),
  'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
    integerReferences: {'unidad_medida_id': 'unidades_medida'},
  ),
  'LEGACY_ATTRIBUTE_DEFINITION': _SyncEntitySpec(
    table: 'atributos_def',
    identityColumn: 'sync_id',
    integerReferences: {'categoria_id': 'categorias'},
  ),
  'PRICE_LIST': _SyncEntitySpec(table: 'listas_precios'),
  'CLIENT': _SyncEntitySpec(table: 'clientes'),
  'ORDER_SHEET': _SyncEntitySpec(table: 'hojas_pedido'),
  'ORDER': _SyncEntitySpec(table: 'pedidos'),
  'ORDER_ITEM': _SyncEntitySpec(table: 'pedido_items'),
  'QUOTE': _SyncEntitySpec(table: 'cotizaciones'),
  'QUOTE_ITEM': _SyncEntitySpec(table: 'cotizacion_items'),
  'PREPARATION': _SyncEntitySpec(table: 'preparacion_productos'),
  'PREPARATION_STOCK_MOVEMENT': _SyncEntitySpec(
    table: 'preparacion_disponible_movimientos',
  ),
  'ORDER_LOAD': _SyncEntitySpec(table: 'pedido_cargas'),
  'ORDER_HISTORY': _SyncEntitySpec(table: 'pedido_historial'),
  'ORDER_SHEET_HISTORY': _SyncEntitySpec(table: 'hoja_historial'),
};
