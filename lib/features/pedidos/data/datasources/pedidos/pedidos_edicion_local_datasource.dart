part of '../pedidos_local_datasource.dart';

extension PedidosEdicionLocalDatasource on PedidosLocalDatasource {
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async {
    if (items.isEmpty) throw StateError('El carrito está vacío.');
    final db = await _db;
    return db.transaction((txn) async {
      final pedidos = await txn.rawQuery(
        '''
        SELECT p.id, p.codigo, p.estado, p.vendedor, p.hoja_id,
               h.codigo AS hoja_codigo
        FROM pedidos p
        INNER JOIN hojas_pedido h ON h.id = p.hoja_id
        WHERE p.id = ?
        LIMIT 1
        ''',
        [pedidoId],
      );
      if (pedidos.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final pedido = pedidos.first;
      final estadoAnterior = _normalizarEstadoPedido(
        pedido['estado'] as String? ?? '',
      );
      if (estadoAnterior == 'cancelado') {
        throw StateError('Reactiva el pedido antes de editarlo.');
      }
      if (estadoAnterior == 'entregado') {
        throw StateError('Un pedido entregado no puede modificarse.');
      }

      final clienteId = await _obtenerOCrearCliente(txn, cliente);
      final existingRows = await txn.query(
        'pedido_items',
        columns: ['id'],
        where: 'pedido_id = ? AND activo = 1',
        whereArgs: [pedidoId],
      );
      final existingIds = existingRows
          .map((row) => row['id'] as String)
          .toSet();
      final incomingExistingIds = items
          .map((item) => item.pedidoItemId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!existingIds.containsAll(incomingExistingIds)) {
        throw StateError(
          'Una de las líneas editadas ya no pertenece a este pedido.',
        );
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
        'cotizaciones',
        {'estado': 'Archivada', 'actualizado_en': now},
        where: "pedido_id = ? AND LOWER(estado) IN ('generada', 'borrador')",
        whereArgs: [pedidoId],
      );

      await txn.update(
        'pedido_items',
        {'activo': 0},
        where: 'pedido_id = ? AND activo = 1',
        whereArgs: [pedidoId],
      );

      var agregadas = 0;
      var actualizadas = 0;
      for (final item in items) {
        final storedId = item.pedidoItemId.trim();
        if (storedId.isNotEmpty && existingIds.contains(storedId)) {
          final count = await txn.update(
            'pedido_items',
            _pedidoItemValues(item, pedidoId: pedidoId, itemId: storedId),
            where: 'id = ? AND pedido_id = ?',
            whereArgs: [storedId, pedidoId],
          );
          if (count != 1) {
            throw StateError('No se pudo actualizar una línea del pedido.');
          }
          actualizadas++;
        } else {
          await txn.insert(
            'pedido_items',
            _pedidoItemValues(
              item,
              pedidoId: pedidoId,
              itemId: const Uuid().v4(),
            ),
          );
          agregadas++;
        }
      }

      final subtotal = items.fold<double>(
        0,
        (total, item) => total + (item.subtotal ?? 0),
      );
      final parcial = items.any((item) => item.precioUnitario == null);
      await txn.update(
        'pedidos',
        {
          'cliente_id': clienteId,
          'vendedor': vendedor,
          'estado': 'Pendiente',
          'subtotal_conocido': subtotal,
          'total_parcial': parcial ? 1 : 0,
          'sincronizado': 0,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );

      final removed = existingIds.difference(incomingExistingIds).length;
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Pedido editado • estado Pendiente',
        observacion:
            '$actualizadas líneas actualizadas · $agregadas agregadas · '
            '$removed retiradas. Se reinició preparación y carga; '
            'las cotizaciones anteriores quedaron archivadas.',
        responsable: vendedor,
        creadoEn: now,
      );

      return PedidoRegistrado(
        id: pedidoId,
        codigo: pedido['codigo'] as String,
        cliente: cliente.nombre,
        hojaCodigo: pedido['hoja_codigo'] as String? ?? '',
        estado: 'Pendiente',
      );
    });
  }
}
