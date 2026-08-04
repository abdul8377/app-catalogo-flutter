part of '../pedidos_local_datasource.dart';

extension _PreparacionEstadoLocalDatasource on PedidosLocalDatasource {
  Future<void> _actualizarEstadoPedidoPorPreparacion(
    Transaction txn,
    String pedidoId,
  ) async {
    final rows = await txn.rawQuery(
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
    if (rows.isEmpty) return;
    final totalPreparado = rows.fold<int>(
      0,
      (sum, row) =>
          sum +
          _clampPreparada(
            (row['preparada'] as num? ?? 0).toInt(),
            row['cantidad_base_requerida'] as int? ?? 0,
          ),
    );
    final carga =
        Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM pedido_cargas WHERE pedido_id = ?',
            [pedidoId],
          ),
        ) ??
        0;
    final estado = carga > 0
        ? 'Listo para entregar'
        : totalPreparado <= 0
        ? 'Pendiente'
        : 'En proceso';
    final pedidoActual = await txn.query(
      'pedidos',
      columns: ['estado', 'vendedor'],
      where: 'id = ?',
      whereArgs: [pedidoId],
      limit: 1,
    );
    final estadoAnterior = pedidoActual.isEmpty
        ? ''
        : pedidoActual.first['estado'] as String? ?? '';
    await txn.update(
      'pedidos',
      {'estado': estado, 'sincronizado': 0, 'sync_error': null},
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
    if (_normalizarEstadoPedido(estadoAnterior) !=
        _normalizarEstadoPedido(estado)) {
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Preparación actualizada • estado $estado',
        observacion: '',
        responsable: pedidoActual.isEmpty
            ? null
            : pedidoActual.first['vendedor'] as String?,
        creadoEn: DateTime.now().toIso8601String(),
      );
    }
  }
}
