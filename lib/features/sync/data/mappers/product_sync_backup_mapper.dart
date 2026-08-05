import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'product_sync_mapper.dart';

/// Extiende el agregado PRODUCT con los tres bloques que el formulario móvil
/// guarda directamente en SQLite. De esta forma un bootstrap sobre una tablet
/// vacía puede reconstruir el producto completo y no solo su proyección para
/// catálogo.
class ProductSyncBackupMapper extends ProductSyncMapper {
  const ProductSyncBackupMapper();

  @override
  Future<Map<String, Object?>> exportProductAggregate(
    DatabaseExecutor database, {
    required String productId,
    required String operation,
  }) async {
    final aggregate = await super.exportProductAggregate(
      database,
      productId: productId,
      operation: operation,
    );
    if (operation == 'DELETE' || aggregate.isEmpty) return aggregate;

    final rows = await database.query(
      'productos',
      columns: const [
        'venta_logistica_json',
        'precios_configurados_json',
        'imagenes_configuradas_json',
      ],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) return aggregate;

    final product = rows.single;
    return <String, Object?>{
      ...aggregate,
      'salesConfiguration': _decodeObject(product['venta_logistica_json']),
      'pricingConfiguration': _decodeObject(
        product['precios_configurados_json'],
      ),
      'imageConfiguration': _decodeObject(
        product['imagenes_configuradas_json'],
      ),
    };
  }

  @override
  Future<void> applyProductAggregate(
    DatabaseExecutor database, {
    required String productId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    final aggregate = payload['product'] is Map
        ? Map<String, Object?>.from(payload['product'] as Map)
        : Map<String, Object?>.from(payload);

    final hasSalesConfiguration = aggregate.containsKey('salesConfiguration');
    final hasPricingConfiguration = aggregate.containsKey(
      'pricingConfiguration',
    );
    final hasImageConfiguration = aggregate.containsKey('imageConfiguration');

    await super.applyProductAggregate(
      database,
      productId: productId,
      operation: operation,
      payload: payload,
    );

    if (operation == 'DELETE') return;
    final values = <String, Object?>{};
    if (hasSalesConfiguration) {
      values['venta_logistica_json'] = jsonEncode(
        _object(aggregate['salesConfiguration']),
      );
    }
    if (hasPricingConfiguration) {
      values['precios_configurados_json'] = jsonEncode(
        _object(aggregate['pricingConfiguration']),
      );
    }
    if (hasImageConfiguration) {
      values['imagenes_configuradas_json'] = jsonEncode(
        _object(aggregate['imageConfiguration']),
      );
    }
    if (values.isEmpty) return;

    await database.update(
      'productos',
      values,
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Map<String, Object?> _decodeObject(Object? raw) {
    if (raw is Map) return Map<String, Object?>.from(raw);
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return <String, Object?>{};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map
          ? Map<String, Object?>.from(decoded)
          : <String, Object?>{};
    } on FormatException {
      return <String, Object?>{};
    }
  }

  Map<String, Object?> _object(Object? raw) =>
      raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
}
