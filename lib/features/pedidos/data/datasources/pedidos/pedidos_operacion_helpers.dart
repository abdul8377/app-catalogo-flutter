part of '../pedidos_local_datasource.dart';

extension _PedidosOperacionHelpers on PedidosLocalDatasource {
  Future<void> _completarOperacionPedido(
    Transaction txn, {
    required String pedidoId,
    required bool completarCarga,
    required String observacion,
  }) async {
    final items = await txn.rawQuery(
      '''
      SELECT i.id,
             i.producto_id,
             i.cantidad,
             i.factor_unidad_base,
             i.cantidad * i.factor_unidad_base AS requerida,
             COALESCE(SUM(pp.cantidad_base), 0) AS preparada
      FROM pedido_items i
      LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
      WHERE i.pedido_id = ?
        AND i.activo = 1
      GROUP BY i.id
      ''',
      [pedidoId],
    );
    if (items.isEmpty) {
      throw StateError('El pedido no tiene productos.');
    }
    for (final item in items) {
      final requerida = item['requerida'] as int? ?? 0;
      final preparada = (item['preparada'] as num? ?? 0).toInt();
      final pendiente = (requerida - preparada).clamp(0, requerida);
      if (pendiente <= 0) continue;
      final factor = (item['factor_unidad_base'] as int? ?? 1).clamp(
        1,
        1000000000,
      );
      final presentaciones = (pendiente / factor).ceil();
      await txn.insert('preparacion_productos', {
        'id': const Uuid().v4(),
        'pedido_item_id': item['id'],
        'pedido_id': pedidoId,
        'producto_id': item['producto_id'],
        'cantidad': presentaciones,
        'cantidad_base': pendiente,
        'observacion': observacion.trim().isEmpty
            ? 'Completado por cambio manual de estado'
            : observacion.trim(),
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
    if (!completarCarga) return;
    final cargas = await txn.query(
      'pedido_cargas',
      columns: ['id'],
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
      limit: 1,
    );
    if (cargas.isEmpty) {
      await txn.insert('pedido_cargas', {
        'id': const Uuid().v4(),
        'pedido_id': pedidoId,
        'paquetes': items.length,
        'observacion': observacion.trim().isEmpty
            ? 'Carga completada por cambio manual de estado'
            : observacion.trim(),
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }
}
