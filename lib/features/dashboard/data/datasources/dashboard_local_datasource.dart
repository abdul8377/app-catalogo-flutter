import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/dashboard_data.dart';

class DashboardLocalDatasource {
  const DashboardLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<DashboardData> obtenerDashboard(DashboardFiltro filtro) async {
    final db = await _db;
    final hojaRows = await db.query(
      'hojas_pedido',
      where: "activa = 1 AND LOWER(estado) = 'abierta'",
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    final hojaRow = hojaRows.isEmpty ? null : hojaRows.first;
    final scope = _crearScope(filtro, hojaRow);

    final metricas = (await db.rawQuery('''
      SELECT COUNT(*) AS total_pedidos,
             COUNT(DISTINCT CASE
               WHEN LOWER(p.estado) <> 'cancelado' THEN p.cliente_id
             END) AS total_clientes,
             COALESCE(SUM(CASE
               WHEN LOWER(p.estado) = 'cancelado' THEN 0
               ELSE COALESCE(
                 (
                   SELECT co.total
                   FROM cotizaciones co
                   WHERE co.pedido_id = p.id
                     AND LOWER(co.estado) <> 'borrador'
                   ORDER BY co.version DESC, co.creado_en DESC
                   LIMIT 1
                 ),
                 p.subtotal_conocido
               )
             END), 0) AS subtotal_conocido,
             COALESCE(SUM(CASE
               WHEN LOWER(p.estado) = 'cancelado' THEN 0
               WHEN EXISTS(
                 SELECT 1
                 FROM pedido_items pi
                 WHERE pi.pedido_id = p.id
                   AND pi.precio_unitario IS NULL
               ) AND NOT EXISTS(
                 SELECT 1
                 FROM cotizaciones co
                 WHERE co.pedido_id = p.id
                   AND LOWER(co.estado) <> 'borrador'
               ) THEN 1
               ELSE 0
             END), 0) AS pendientes_valorizar,
             COALESCE(SUM(CASE
               WHEN EXISTS(
                 SELECT 1 FROM pedido_cargas pc WHERE pc.pedido_id = p.id
               ) THEN 1 ELSE 0
             END), 0) AS cargados,
             COALESCE(SUM(CASE
               WHEN LOWER(p.estado) = 'entregado' THEN 1 ELSE 0
             END), 0) AS entregados
      FROM pedidos p
      WHERE ${scope.where}
    ''', scope.args)).first;

    final preparacion = (await db.rawQuery('''
      SELECT COALESCE(SUM(i.cantidad * i.factor_unidad_base), 0) AS requerida,
             COALESCE(SUM(
               MIN(
                 i.cantidad * i.factor_unidad_base,
                 COALESCE(prep.preparada, 0)
               )
             ), 0) AS preparada
      FROM pedido_items i
      INNER JOIN pedidos p ON p.id = i.pedido_id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      WHERE ${scope.where}
        AND LOWER(p.estado) <> 'cancelado'
    ''', scope.args)).first;

    final parcial =
        Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM (
              SELECT p.id,
                     SUM(i.cantidad * i.factor_unidad_base) AS requerida,
                     SUM(
                       MIN(
                         i.cantidad * i.factor_unidad_base,
                         COALESCE(prep.preparada, 0)
                       )
                     ) AS preparada
              FROM pedidos p
              INNER JOIN pedido_items i ON i.pedido_id = p.id
              LEFT JOIN (
                SELECT pedido_item_id, SUM(cantidad_base) AS preparada
                FROM preparacion_productos
                GROUP BY pedido_item_id
              ) prep ON prep.pedido_item_id = i.id
              WHERE ${scope.where}
                AND LOWER(p.estado) <> 'cancelado'
              GROUP BY p.id
              HAVING preparada > 0 AND preparada < requerida
            )
          ''', scope.args),
        ) ??
        0;

    final estados = <String, int>{
      'Pendiente': 0,
      'En proceso': 0,
      'Listo para entregar': 0,
      'Entregado': 0,
      'Cancelado': 0,
    };
    final estadosRows = await db.rawQuery('''
      SELECT CASE
               WHEN LOWER(p.estado) = 'cancelado' THEN 'Cancelado'
               WHEN LOWER(p.estado) = 'entregado' THEN 'Entregado'
               WHEN LOWER(p.estado) LIKE 'listo%' THEN 'Listo para entregar'
               WHEN LOWER(p.estado) LIKE '%proceso%' THEN 'En proceso'
               ELSE 'Pendiente'
             END AS estado_normalizado,
             COUNT(*) AS cantidad
      FROM pedidos p
      WHERE ${scope.where}
      GROUP BY estado_normalizado
    ''', scope.args);
    for (final row in estadosRows) {
      estados[row['estado_normalizado'] as String] = _int(row['cantidad']);
    }

    final productosTopRows = await db.rawQuery('''
      SELECT i.producto_id,
             i.codigo,
             i.nombre,
             COALESCE(pr.marca, '') AS marca,
             i.unidad_base,
             SUM(i.cantidad * i.factor_unidad_base) AS requerida,
             SUM(
               MIN(
                 i.cantidad * i.factor_unidad_base,
                 COALESCE(prep.preparada, 0)
               )
             ) AS preparada,
             COUNT(DISTINCT p.id) AS pedidos
      FROM pedido_items i
      INNER JOIN pedidos p ON p.id = i.pedido_id
      LEFT JOIN productos pr ON pr.id = i.producto_id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      WHERE ${scope.where}
        AND LOWER(p.estado) <> 'cancelado'
      GROUP BY i.producto_id, i.codigo, i.nombre, pr.marca, i.unidad_base
      ORDER BY requerida DESC, pedidos DESC, i.nombre COLLATE NOCASE
      LIMIT 5
    ''', scope.args);

    final cotizacionesRows = await db.rawQuery('''
      SELECT co.id,
             co.pedido_id,
             co.codigo,
             co.total,
             co.estado,
             co.pdf_path,
             co.creado_en,
             p.codigo AS pedido_codigo,
             c.nombre AS cliente_nombre
      FROM cotizaciones co
      INNER JOIN pedidos p ON p.id = co.pedido_id
      INNER JOIN clientes c ON c.id = p.cliente_id
      WHERE ${scope.where}
      ORDER BY co.creado_en DESC, co.version DESC
      LIMIT 5
    ''', scope.args);
    final cotizacionesMetricas = (await db.rawQuery('''
      SELECT COALESCE(SUM(CASE
               WHEN LOWER(co.estado) = 'borrador' THEN 1 ELSE 0
             END), 0) AS borradores,
             COALESCE(SUM(CASE
               WHEN LOWER(co.estado) <> 'borrador' THEN 1 ELSE 0
             END), 0) AS generadas
      FROM cotizaciones co
      INNER JOIN pedidos p ON p.id = co.pedido_id
      WHERE ${scope.where}
    ''', scope.args)).first;

    final pedidosRows = await db.rawQuery('''
      SELECT p.id,
             p.codigo,
             p.estado,
             p.sincronizado,
             p.creado_en,
             c.nombre AS cliente_nombre,
             COUNT(i.id) AS productos,
             CASE
               WHEN cv.id IS NOT NULL THEN 0
               ELSE COALESCE(SUM(CASE
                 WHEN i.precio_unitario IS NULL THEN 1 ELSE 0
               END), 0)
             END AS productos_sin_precio,
             COALESCE(cv.total, p.subtotal_conocido) AS total
      FROM pedidos p
      INNER JOIN clientes c ON c.id = p.cliente_id
      LEFT JOIN pedido_items i ON i.pedido_id = p.id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
        FROM cotizaciones co
        WHERE co.pedido_id = p.id
          AND LOWER(co.estado) <> 'borrador'
        ORDER BY co.version DESC, co.creado_en DESC
        LIMIT 1
      )
      WHERE ${scope.where}
      GROUP BY p.id
      ORDER BY p.creado_en DESC
      LIMIT 5
    ''', scope.args);

    final clientesRows = await db.rawQuery('''
      SELECT c.id,
             c.nombre,
             c.direccion,
             COUNT(DISTINCT p.id) AS pedidos,
             COALESCE(SUM(
               COALESCE(
                 (
                   SELECT co.total
                   FROM cotizaciones co
                   WHERE co.pedido_id = p.id
                     AND LOWER(co.estado) <> 'borrador'
                   ORDER BY co.version DESC, co.creado_en DESC
                   LIMIT 1
                 ),
                 p.subtotal_conocido
               )
             ), 0) AS subtotal,
             MAX(p.creado_en) AS ultimo_pedido
      FROM clientes c
      INNER JOIN pedidos p ON p.cliente_id = c.id
      WHERE ${scope.where}
        AND LOWER(p.estado) <> 'cancelado'
      GROUP BY c.id
      ORDER BY ultimo_pedido DESC, pedidos DESC
      LIMIT 5
    ''', scope.args);

    final actividadRows = await db.rawQuery(
      '''
      SELECT ph.evento,
             ph.observacion AS detalle,
             ph.creado_en,
             'pedido' AS tipo
      FROM pedido_historial ph
      INNER JOIN pedidos p ON p.id = ph.pedido_id
      WHERE ${scope.where}
      UNION ALL
      SELECT 'Cotización ' || co.codigo || ' guardada' AS evento,
             co.estado AS detalle,
             co.creado_en,
             'cotizacion' AS tipo
      FROM cotizaciones co
      INNER JOIN pedidos p ON p.id = co.pedido_id
      WHERE ${scope.where}
      ORDER BY creado_en DESC
      LIMIT 8
    ''',
      [...scope.args, ...scope.args],
    );

    final faltantesRows = await db.rawQuery('''
      SELECT i.producto_id,
             i.codigo,
             i.nombre,
             i.unidad_base,
             SUM(
               MAX(
                 (i.cantidad * i.factor_unidad_base) -
                   COALESCE(prep.preparada, 0),
                 0
               )
             ) AS pendiente,
             COUNT(DISTINCT CASE
               WHEN COALESCE(prep.preparada, 0) <
                    i.cantidad * i.factor_unidad_base
               THEN p.id
             END) AS pedidos_afectados
      FROM pedido_items i
      INNER JOIN pedidos p ON p.id = i.pedido_id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      WHERE ${scope.where}
        AND LOWER(p.estado) <> 'cancelado'
      GROUP BY i.producto_id, i.codigo, i.nombre, i.unidad_base
      HAVING pendiente > 0
      ORDER BY pendiente DESC, pedidos_afectados DESC
      LIMIT 5
    ''', scope.args);

    final listosRows = await db.rawQuery('''
      SELECT p.id,
             p.codigo,
             c.nombre AS cliente_nombre,
             c.direccion,
             COUNT(i.id) AS productos
      FROM pedidos p
      INNER JOIN hojas_pedido h ON h.id = p.hoja_id
      INNER JOIN clientes c ON c.id = p.cliente_id
      INNER JOIN pedido_items i ON i.pedido_id = p.id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      LEFT JOIN pedido_cargas pc ON pc.pedido_id = p.id
      WHERE ${scope.where}
        AND h.activa = 1
        AND LOWER(h.estado) = 'abierta'
        AND LOWER(p.estado) NOT IN (
          'cancelado',
          'entregado',
          'listo para entregar'
        )
        AND pc.id IS NULL
      GROUP BY p.id
      HAVING SUM(
        CASE
          WHEN COALESCE(prep.preparada, 0) <
               i.cantidad * i.factor_unidad_base
          THEN 1 ELSE 0
        END
      ) = 0
      ORDER BY p.creado_en ASC
      LIMIT 5
    ''', scope.args);

    final syncRow = (await db.rawQuery('''
      SELECT
        (
          SELECT COUNT(*)
          FROM pedidos p
          WHERE ${scope.where} AND p.sincronizado = 0
        ) AS pedidos_pendientes,
        (
          SELECT COUNT(*)
          FROM hojas_pedido h
          WHERE h.sincronizado = 0
        ) AS hojas_pendientes,
        (
          SELECT COUNT(*)
          FROM sync_queue
          WHERE estado = 'pendiente'
        ) AS cola_pendiente,
        (
          SELECT COUNT(*)
          FROM sync_queue
          WHERE estado = 'error'
        ) AS errores,
        (
          SELECT MAX(creado_en)
          FROM pedido_historial
          WHERE LOWER(evento) LIKE '%sincronizaci%'
        ) AS ultima_sincronizacion
    ''', scope.args)).first;

    return DashboardData(
      totalPedidos: _int(metricas['total_pedidos']),
      subtotalConocido: _double(metricas['subtotal_conocido']),
      pedidosPendientesValorizar: _int(metricas['pendientes_valorizar']),
      totalClientes: _int(metricas['total_clientes']),
      unidadesRequeridas: _int(preparacion['requerida']),
      unidadesPreparadas: _int(preparacion['preparada']),
      pedidosCargados: _int(metricas['cargados']),
      pedidosEntregados: _int(metricas['entregados']),
      pedidosListosCargar: listosRows.length,
      pedidosPreparacionParcial: parcial,
      cotizacionesGeneradas: _int(cotizacionesMetricas['generadas']),
      cotizacionesBorradores: _int(cotizacionesMetricas['borradores']),
      pedidosPorEstado: estados,
      productosTop: productosTopRows.map(_productoTop).toList(),
      cotizaciones: cotizacionesRows.map(_cotizacion).toList(),
      pedidosRecientes: pedidosRows.map(_pedidoReciente).toList(),
      clientes: clientesRows.map(_cliente).toList(),
      actividad: actividadRows.map(_actividad).toList(),
      principalesFaltantes: faltantesRows.map(_faltante).toList(),
      pedidosListos: listosRows.map(_pedidoListo).toList(),
      sincronizacion: DashboardSincronizacion(
        pedidosPendientes: _int(syncRow['pedidos_pendientes']),
        hojasPendientes: _int(syncRow['hojas_pendientes']),
        operacionesEnCola: _int(syncRow['cola_pendiente']),
        errores: _int(syncRow['errores']),
        ultimaSincronizacion: _dateOrNull(syncRow['ultima_sincronizacion']),
      ),
      hojaActiva: await _obtenerHojaActiva(db, hojaRow),
    );
  }

  Future<DashboardHojaActiva?> _obtenerHojaActiva(
    Database db,
    Map<String, Object?>? hoja,
  ) async {
    if (hoja == null) return null;
    final row = (await db.rawQuery(
      '''
      SELECT h.id,
             h.codigo,
             h.estado,
             h.vendedor,
             h.creado_en,
             (SELECT COUNT(*) FROM pedidos p WHERE p.hoja_id = h.id)
               AS pedidos,
             (
               SELECT COUNT(DISTINCT p.cliente_id)
               FROM pedidos p
               WHERE p.hoja_id = h.id
                 AND LOWER(p.estado) <> 'cancelado'
             ) AS clientes,
             (
               SELECT COUNT(DISTINCT i.producto_id)
               FROM pedido_items i
               INNER JOIN pedidos p ON p.id = i.pedido_id
               WHERE p.hoja_id = h.id
                 AND LOWER(p.estado) <> 'cancelado'
             ) AS productos,
             (
               SELECT COALESCE(SUM(
                 COALESCE(
                   (
                     SELECT co.total
                     FROM cotizaciones co
                     WHERE co.pedido_id = p.id
                       AND LOWER(co.estado) <> 'borrador'
                     ORDER BY co.version DESC, co.creado_en DESC
                     LIMIT 1
                   ),
                   p.subtotal_conocido
                 )
               ), 0)
               FROM pedidos p
               WHERE p.hoja_id = h.id
                 AND LOWER(p.estado) <> 'cancelado'
             ) AS subtotal,
             (
               SELECT COUNT(*)
               FROM pedidos p
               WHERE p.hoja_id = h.id
                 AND LOWER(p.estado) <> 'cancelado'
                 AND EXISTS(
                   SELECT 1
                   FROM pedido_items i
                   WHERE i.pedido_id = p.id
                     AND i.precio_unitario IS NULL
                 )
                 AND NOT EXISTS(
                   SELECT 1
                   FROM cotizaciones co
                   WHERE co.pedido_id = p.id
                     AND LOWER(co.estado) <> 'borrador'
                 )
             ) AS pendientes_precio
      FROM hojas_pedido h
      WHERE h.id = ?
      LIMIT 1
    ''',
      [hoja['id']],
    )).first;
    return DashboardHojaActiva(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      estado: row['estado'] as String? ?? 'Abierta',
      vendedor: row['vendedor'] as String? ?? '',
      fecha: _date(row['creado_en']),
      pedidos: _int(row['pedidos']),
      clientes: _int(row['clientes']),
      productos: _int(row['productos']),
      subtotal: _double(row['subtotal']),
      pendientesPrecio: _int(row['pendientes_precio']),
    );
  }

  _DashboardScope _crearScope(
    DashboardFiltro filtro,
    Map<String, Object?>? hoja,
  ) {
    if (filtro.periodo == DashboardPeriodoTipo.hojaActiva) {
      return hoja == null
          ? const _DashboardScope('1 = 0', [])
          : _DashboardScope('p.hoja_id = ?', [hoja['id']]);
    }

    final now = DateTime.now();
    late DateTime inicio;
    late DateTime finExclusivo;
    switch (filtro.periodo) {
      case DashboardPeriodoTipo.hoy:
        inicio = DateTime(now.year, now.month, now.day);
        finExclusivo = inicio.add(const Duration(days: 1));
      case DashboardPeriodoTipo.semana:
        final hoy = DateTime(now.year, now.month, now.day);
        inicio = hoy.subtract(Duration(days: hoy.weekday - 1));
        finExclusivo = inicio.add(const Duration(days: 7));
      case DashboardPeriodoTipo.mes:
        inicio = DateTime(now.year, now.month);
        finExclusivo = DateTime(now.year, now.month + 1);
      case DashboardPeriodoTipo.personalizado:
        final fechaInicio = filtro.fechaInicio ?? now;
        final fechaFin = filtro.fechaFin ?? fechaInicio;
        inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        finExclusivo = DateTime(
          fechaFin.year,
          fechaFin.month,
          fechaFin.day,
        ).add(const Duration(days: 1));
      case DashboardPeriodoTipo.hojaActiva:
        throw StateError('El periodo de hoja activa ya fue procesado.');
    }
    return _DashboardScope('p.creado_en >= ? AND p.creado_en < ?', [
      inicio.toIso8601String(),
      finExclusivo.toIso8601String(),
    ]);
  }

  DashboardProductoTop _productoTop(Map<String, Object?> row) =>
      DashboardProductoTop(
        productoId: row['producto_id'] as String,
        nombre: row['nombre'] as String? ?? '',
        codigo: row['codigo'] as String? ?? '',
        marca: row['marca'] as String? ?? '',
        unidadBase: row['unidad_base'] as String? ?? 'UND',
        cantidadRequerida: _int(row['requerida']),
        cantidadPreparada: _int(row['preparada']),
        pedidos: _int(row['pedidos']),
      );

  DashboardCotizacion _cotizacion(Map<String, Object?> row) =>
      DashboardCotizacion(
        id: row['id'] as String,
        pedidoId: row['pedido_id'] as String,
        codigo: row['codigo'] as String? ?? '',
        pedidoCodigo: row['pedido_codigo'] as String? ?? '',
        cliente: row['cliente_nombre'] as String? ?? '',
        total: _double(row['total']),
        estado: row['estado'] as String? ?? 'Borrador',
        fecha: _date(row['creado_en']),
        tienePdf: (row['pdf_path'] as String? ?? '').trim().isNotEmpty,
      );

  DashboardPedidoReciente _pedidoReciente(Map<String, Object?> row) =>
      DashboardPedidoReciente(
        id: row['id'] as String,
        codigo: row['codigo'] as String? ?? '',
        cliente: row['cliente_nombre'] as String? ?? '',
        productos: _int(row['productos']),
        total: _double(row['total']),
        productosSinPrecio: _int(row['productos_sin_precio']),
        estado: row['estado'] as String? ?? 'Pendiente',
        fecha: _date(row['creado_en']),
        sincronizado: _int(row['sincronizado']) == 1,
      );

  DashboardCliente _cliente(Map<String, Object?> row) => DashboardCliente(
    id: row['id'] as String,
    nombre: row['nombre'] as String? ?? '',
    pedidos: _int(row['pedidos']),
    subtotalConocido: _double(row['subtotal']),
    ultimoPedido: _date(row['ultimo_pedido']),
    direccion: row['direccion'] as String? ?? '',
  );

  DashboardActividad _actividad(Map<String, Object?> row) => DashboardActividad(
    evento: row['evento'] as String? ?? '',
    fecha: _date(row['creado_en']),
    tipo: row['tipo'] as String? ?? 'pedido',
    detalle: row['detalle'] as String? ?? '',
  );

  DashboardFaltante _faltante(Map<String, Object?> row) => DashboardFaltante(
    productoId: row['producto_id'] as String,
    nombre: row['nombre'] as String? ?? '',
    codigo: row['codigo'] as String? ?? '',
    unidadBase: row['unidad_base'] as String? ?? 'UND',
    cantidadPendiente: _int(row['pendiente']),
    pedidosAfectados: _int(row['pedidos_afectados']),
  );

  DashboardPedidoListo _pedidoListo(Map<String, Object?> row) =>
      DashboardPedidoListo(
        id: row['id'] as String,
        codigo: row['codigo'] as String? ?? '',
        cliente: row['cliente_nombre'] as String? ?? '',
        productos: _int(row['productos']),
        direccion: row['direccion'] as String? ?? '',
      );

  int _int(Object? value) => (value as num? ?? 0).toInt();

  double _double(Object? value) => (value as num? ?? 0).toDouble();

  DateTime _date(Object? value) =>
      DateTime.tryParse(value as String? ?? '') ?? DateTime.now();

  DateTime? _dateOrNull(Object? value) =>
      DateTime.tryParse(value as String? ?? '');
}

class _DashboardScope {
  const _DashboardScope(this.where, this.args);

  final String where;
  final List<Object?> args;
}
