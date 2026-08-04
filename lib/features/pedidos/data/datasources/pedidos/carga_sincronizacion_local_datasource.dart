part of '../pedidos_local_datasource.dart';

extension CargaSincronizacionLocalDatasource on PedidosLocalDatasource {
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) async {
    if (paquetes <= 0) {
      throw StateError('La cantidad de paquetes debe ser mayor que cero.');
    }
    final db = await _db;
    await db.transaction((txn) async {
      final pedidoActivo = await txn.rawQuery(
        '''
        SELECT p.id
        FROM pedidos p
        INNER JOIN hojas_pedido h ON h.id = p.hoja_id
        WHERE p.id = ?
          AND h.activa = 1
          AND h.estado = 'Abierta'
          AND LOWER(p.estado) NOT IN ('cancelado', 'listo para entregar', 'entregado')
        LIMIT 1
        ''',
        [pedidoId],
      );
      if (pedidoActivo.isEmpty) {
        throw StateError(
          'El pedido ya no tiene una carga pendiente en la hoja activa.',
        );
      }
      final items = await txn.rawQuery(
        '''
        SELECT i.id,
               i.cantidad * i.factor_unidad_base AS cantidad_base_requerida,
               COALESCE(SUM(pp.cantidad_base), 0) AS preparada
        FROM pedido_items i
        LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
        WHERE i.pedido_id = ?
          AND i.activo = 1
        GROUP BY i.id
        ''',
        [pedidoId],
      );
      if (items.isEmpty) throw StateError('El pedido no tiene productos.');
      final incompletos = items.where((row) {
        final solicitada = row['cantidad_base_requerida'] as int? ?? 0;
        final preparada = (row['preparada'] as num? ?? 0).toInt();
        return preparada < solicitada;
      });
      if (incompletos.isNotEmpty) {
        throw StateError('El pedido aún tiene productos pendientes.');
      }
      await txn.delete(
        'pedido_cargas',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      await txn.insert('pedido_cargas', {
        'id': const Uuid().v4(),
        'pedido_id': pedidoId,
        'paquetes': paquetes,
        'observacion': observacion,
        'creado_en': DateTime.now().toIso8601String(),
      });
      await txn.update(
        'pedidos',
        {
          'estado': 'Listo para entregar',
          'sincronizado': 0,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      final pedido = await txn.query(
        'pedidos',
        columns: ['vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Carga confirmada • pedido listo para entregar',
        observacion: observacion,
        responsable: pedido.isEmpty
            ? null
            : pedido.first['vendedor'] as String?,
        creadoEn: DateTime.now().toIso8601String(),
      );
    });
  }

  Future<void> reintentarSincronizacionPedido(String pedidoId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pedido = await txn.query(
        'pedidos',
        columns: ['id', 'vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      if (pedido.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      await txn.update(
        'pedidos',
        {'sincronizado': 1, 'sync_error': null},
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Sincronización local completada',
        observacion: '',
        responsable: pedido.first['vendedor'] as String?,
        creadoEn: DateTime.now().toIso8601String(),
      );
    });
  }
}
