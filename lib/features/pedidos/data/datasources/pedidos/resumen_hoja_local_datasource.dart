part of '../pedidos_local_datasource.dart';

extension ResumenHojaLocalDatasource on PedidosLocalDatasource {
  Future<ResumenHoy> obtenerResumenHoy() async {
    final db = await _db;
    final orderStats = (await db.rawQuery('''
      SELECT
        SUM(CASE WHEN LOWER(estado) = 'pendiente' THEN 1 ELSE 0 END) AS pendientes,
        SUM(CASE WHEN LOWER(estado) LIKE '%proceso%' THEN 1 ELSE 0 END) AS en_proceso,
        SUM(CASE WHEN LOWER(estado) LIKE 'listo%' THEN 1 ELSE 0 END) AS listos,
        SUM(CASE WHEN LOWER(estado) = 'entregado' THEN 1 ELSE 0 END) AS entregados,
        SUM(CASE WHEN sincronizado = 0 THEN 1 ELSE 0 END) AS pedidos_sin_sync
      FROM pedidos
      WHERE DATE(creado_en, 'localtime') = DATE('now', 'localtime')
        AND LOWER(estado) <> 'cancelado'
    ''')).first;
    final unpriced =
        Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM pedido_items i
            INNER JOIN pedidos p ON p.id = i.pedido_id
            LEFT JOIN cotizaciones cv ON cv.id = (
              SELECT co.id
              FROM cotizaciones co
              WHERE co.pedido_id = p.id
                AND LOWER(co.estado) = 'generada'
              ORDER BY co.version DESC, co.creado_en DESC
              LIMIT 1
            )
            LEFT JOIN cotizacion_items ci
              ON ci.cotizacion_id = cv.id
             AND ci.pedido_item_id = i.id
            WHERE i.activo = 1
              AND DATE(p.creado_en, 'localtime') = DATE('now', 'localtime')
              AND LOWER(p.estado) <> 'cancelado'
              AND COALESCE(ci.precio_cotizacion, i.precio_unitario) IS NULL
          '''),
        ) ??
        0;
    final queuePending =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM sync_queue WHERE estado = 'pendiente'",
          ),
        ) ??
        0;
    final activeSheet = await db.query(
      'hojas_pedido',
      columns: ['vendedor', 'sincronizado'],
      where: "activa = 1 AND estado = 'Abierta'",
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    final sheetPending =
        activeSheet.isNotEmpty &&
            (activeSheet.first['sincronizado'] as int? ?? 0) == 0
        ? 1
        : 0;
    return ResumenHoy(
      vendedorNombre: activeSheet.isEmpty
          ? 'Usuario'
          : (activeSheet.first['vendedor'] as String? ?? '').trim().isEmpty
          ? 'Usuario'
          : activeSheet.first['vendedor'] as String,
      pedidosPendientes: orderStats['pendientes'] as int? ?? 0,
      pedidosEnProceso: orderStats['en_proceso'] as int? ?? 0,
      pedidosListos: orderStats['listos'] as int? ?? 0,
      pedidosEntregados: orderStats['entregados'] as int? ?? 0,
      productosSinPrecio: unpriced,
      cambiosSinSincronizar:
          (orderStats['pedidos_sin_sync'] as int? ?? 0) +
          sheetPending +
          queuePending,
    );
  }

  Future<HojaPedidoActiva?> obtenerHojaActiva() async {
    final rows = await (await _db).query(
      'hojas_pedido',
      where: "activa = 1 AND estado = 'Abierta'",
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HojaPedidoActiva(
      id: rows.first['id'] as String,
      codigo: rows.first['codigo'] as String,
      estado: rows.first['estado'] as String,
    );
  }

  Future<HojaPedidoActiva> crearHojaActiva({
    String vendedor = 'Alfonzo Esteban',
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final now = DateTime.now();
      final count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM hojas_pedido WHERE codigo LIKE ?',
              ['HP-${now.year}-%'],
            ),
          ) ??
          0;
      final codigo = 'HP-${now.year}-${(count + 1).toString().padLeft(3, '0')}';
      final id = const Uuid().v4();
      await txn.update('hojas_pedido', {'activa': 0});
      await txn.insert('hojas_pedido', {
        'id': id,
        'codigo': codigo,
        'estado': 'Abierta',
        'activa': 1,
        'vendedor': vendedor,
        'sincronizado': 0,
        'creado_en': now.toIso8601String(),
      });
      await txn.insert('hoja_historial', {
        'id': const Uuid().v4(),
        'hoja_id': id,
        'evento': 'Hoja $codigo creada',
        'responsable': vendedor,
        'creado_en': now.toIso8601String(),
      });
      return HojaPedidoActiva(id: id, codigo: codigo, estado: 'Abierta');
    });
  }
}
