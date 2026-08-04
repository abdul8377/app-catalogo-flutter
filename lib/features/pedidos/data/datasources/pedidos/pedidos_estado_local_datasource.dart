part of '../pedidos_local_datasource.dart';

extension PedidosEstadoLocalDatasource on PedidosLocalDatasource {
  Future<void> cambiarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String observacion = '',
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pedidoRows = await txn.query(
        'pedidos',
        columns: ['id', 'codigo', 'estado', 'vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      if (pedidoRows.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final pedido = pedidoRows.first;
      final actual = _normalizarEstadoPedido(pedido['estado'] as String? ?? '');
      final nuevo = _normalizarEstadoPedido(nuevoEstado);
      if (actual == 'cancelado') {
        throw StateError(
          'Un pedido cancelado no puede regresar al flujo operativo.',
        );
      }
      if (nuevo == 'cancelado') {
        throw StateError(
          'Utiliza la acción Cancelar pedido para registrar el motivo.',
        );
      }
      if (actual == nuevo) return;
      final now = DateTime.now().toIso8601String();
      if (nuevo == 'pendiente') {
        await txn.delete(
          'preparacion_productos',
          where: 'pedido_id = ?',
          whereArgs: [pedidoId],
        );
        await txn.delete(
          'pedido_cargas',
          where: 'pedido_id = ?',
          whereArgs: [pedidoId],
        );
      } else if (nuevo == 'en_proceso') {
        await txn.delete(
          'pedido_cargas',
          where: 'pedido_id = ?',
          whereArgs: [pedidoId],
        );
      } else if (nuevo == 'listo' || nuevo == 'entregado') {
        await _completarOperacionPedido(
          txn,
          pedidoId: pedidoId,
          completarCarga: true,
          observacion: observacion,
        );
      }
      await txn.update(
        'pedidos',
        {
          'estado': _estadoPedidoLabel(nuevo),
          'sincronizado': 0,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento:
            'Estado actualizado: ${_estadoPedidoLabel(actual)} → ${_estadoPedidoLabel(nuevo)}',
        observacion: observacion,
        responsable: pedido['vendedor'] as String?,
        creadoEn: now,
      );
    });
  }

  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) async {
    final motivoLimpio = motivo.trim();
    if (motivoLimpio.isEmpty) {
      throw StateError('El motivo de cancelación es obligatorio.');
    }
    final db = await _db;
    await db.transaction((txn) async {
      final pedidoRows = await txn.query(
        'pedidos',
        columns: ['id', 'codigo', 'estado', 'vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      if (pedidoRows.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final pedido = pedidoRows.first;
      final actual = _normalizarEstadoPedido(pedido['estado'] as String? ?? '');
      if (actual == 'entregado' || actual == 'cancelado') {
        throw StateError(
          'No se puede cancelar un pedido ${_estadoPedidoLabel(actual).toLowerCase()}.',
        );
      }
      final now = DateTime.now().toIso8601String();
      await txn.update(
        'pedidos',
        {'estado': 'Cancelado', 'sincronizado': 0, 'sync_error': null},
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Pedido cancelado',
        observacion: motivoLimpio,
        responsable: pedido['vendedor'] as String?,
        creadoEn: now,
      );
    });
  }

  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'pedidos',
        columns: ['id', 'estado', 'vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final current = _normalizarEstadoPedido(
        rows.first['estado'] as String? ?? '',
      );
      if (current != 'cancelado') {
        throw StateError('Solo se puede reactivar un pedido cancelado.');
      }
      await txn.delete(
        'preparacion_productos',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      await txn.delete(
        'pedido_cargas',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      final now = DateTime.now().toIso8601String();
      await txn.update(
        'pedidos',
        {'estado': 'Pendiente', 'sincronizado': 0, 'sync_error': null},
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Pedido reactivado • estado Pendiente',
        observacion: observacion.trim(),
        responsable: rows.first['vendedor'] as String?,
        creadoEn: now,
      );
    });
  }
}
