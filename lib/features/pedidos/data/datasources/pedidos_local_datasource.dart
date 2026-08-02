import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/pedido_resumen.dart';
import '../../domain/entities/producto_consolidado.dart';
import '../../domain/entities/resumen_hoy.dart';

class PedidosLocalDatasource {
  const PedidosLocalDatasource(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

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
            WHERE DATE(p.creado_en, 'localtime') = DATE('now', 'localtime')
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

  Future<HojaPedidoActiva> crearHojaActiva() async {
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
        'vendedor': 'Alfonzo Esteban',
        'sincronizado': 0,
        'creado_en': now.toIso8601String(),
      });
      await txn.insert('hoja_historial', {
        'id': const Uuid().v4(),
        'hoja_id': id,
        'evento': 'Hoja $codigo creada',
        'responsable': 'Alfonzo Esteban',
        'creado_en': now.toIso8601String(),
      });
      return HojaPedidoActiva(id: id, codigo: codigo, estado: 'Abierta');
    });
  }

  Future<List<PedidoResumen>> obtenerPedidosResumen() async {
    final rows = await (await _db).rawQuery('''
      SELECT p.id,
             p.codigo,
             p.creado_en,
             p.estado,
             p.vendedor,
             p.subtotal_conocido,
             p.total_parcial,
             p.sincronizado,
             p.sync_error,
             h.codigo AS hoja_codigo,
             c.id AS cliente_id,
             c.nombre AS cliente_nombre,
             c.telefono,
             c.dni,
             c.ruc,
             c.direccion,
             c.referencia,
             c.foto_ubicacion_path,
             COUNT(i.id) AS cantidad_productos,
             COUNT(DISTINCT i.presentacion) AS cantidad_presentaciones,
             CASE
               WHEN cv.id IS NOT NULL THEN 0
               ELSE SUM(CASE WHEN i.precio_unitario IS NULL THEN 1 ELSE 0 END)
             END AS productos_sin_precio,
             GROUP_CONCAT(i.nombre, '|||') AS productos_resumen,
             GROUP_CONCAT(DISTINCT pr.empresa) AS empresas,
             GROUP_CONCAT(DISTINCT pr.marca) AS marcas,
             GROUP_CONCAT(DISTINCT pr.categoria) AS categorias,
             (SELECT COUNT(*)
                FROM cotizaciones co
               WHERE co.pedido_id = p.id
                 AND LOWER(co.estado) = 'generada') AS cotizaciones_generadas,
             cv.id AS cotizacion_vigente_id,
             cv.codigo AS cotizacion_vigente_codigo,
             cv.codigo_base AS cotizacion_vigente_codigo_base,
             cv.version AS cotizacion_vigente_version,
             cv.subtotal AS cotizacion_subtotal_productos,
             (
               cv.subtotal - COALESCE(
                 (SELECT SUM(ci.subtotal)
                    FROM cotizacion_items ci
                   WHERE ci.cotizacion_id = cv.id),
                 cv.subtotal
               )
             ) + COALESCE(cv.descuento_global, 0) AS cotizacion_descuento,
             cv.total AS cotizacion_total
      FROM pedidos p
      INNER JOIN clientes c ON c.id = p.cliente_id
      INNER JOIN hojas_pedido h ON h.id = p.hoja_id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = p.id
           AND LOWER(co.estado) = 'generada'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      LEFT JOIN pedido_items i ON i.pedido_id = p.id
      LEFT JOIN productos pr ON pr.id = i.producto_id
      GROUP BY p.id
      ORDER BY p.creado_en DESC
    ''');
    return rows.map(_pedidoResumenFromMap).toList();
  }

  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) async {
    final db = await _db;
    final pedidoRows = await db.rawQuery(
      '''
      SELECT p.id,
             p.codigo,
             p.creado_en,
             p.estado,
             p.vendedor,
             p.subtotal_conocido,
             p.total_parcial,
             p.sincronizado,
             p.sync_error,
             h.codigo AS hoja_codigo,
             c.id AS cliente_id,
             c.nombre AS cliente_nombre,
             c.telefono,
             c.dni,
             c.ruc,
             c.direccion,
             c.referencia,
             c.foto_ubicacion_path,
             c.observaciones,
             cv.id AS cotizacion_vigente_id,
             cv.codigo AS cotizacion_vigente_codigo,
             cv.codigo_base AS cotizacion_vigente_codigo_base,
             cv.version AS cotizacion_vigente_version,
             cv.subtotal AS cotizacion_subtotal_productos,
             cv.descuento_global AS cotizacion_descuento_global,
             cv.descuento_global_porcentaje,
             cv.descuento_global_monto,
             cv.observaciones AS cotizacion_observaciones,
             cv.total AS cotizacion_total,
             COALESCE(
               (SELECT SUM(ci.subtotal)
                  FROM cotizacion_items ci
                 WHERE ci.cotizacion_id = cv.id),
               cv.subtotal
             ) AS cotizacion_subtotal_neto_productos,
             CASE
               WHEN EXISTS(
                 SELECT 1
                   FROM pedido_items px
                   LEFT JOIN preparacion_productos ppx
                     ON ppx.pedido_item_id = px.id
                  WHERE px.pedido_id = p.id
                  GROUP BY px.id
                 HAVING COALESCE(SUM(ppx.cantidad_base), 0) > 0
               ) THEN 1 ELSE 0
             END AS tiene_preparacion,
             CASE
               WHEN NOT EXISTS(
                 SELECT 1
                   FROM pedido_items px
                   LEFT JOIN preparacion_productos ppx
                     ON ppx.pedido_item_id = px.id
                  WHERE px.pedido_id = p.id
                  GROUP BY px.id
                 HAVING COALESCE(SUM(ppx.cantidad_base), 0)
                        < px.cantidad * px.factor_unidad_base
               ) THEN 1 ELSE 0
             END AS preparacion_completa,
             CASE WHEN pc.id IS NULL THEN 0 ELSE 1 END AS carga_completa
      FROM pedidos p
      INNER JOIN clientes c ON c.id = p.cliente_id
      INNER JOIN hojas_pedido h ON h.id = p.hoja_id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = p.id
           AND LOWER(co.estado) = 'generada'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      LEFT JOIN pedido_cargas pc ON pc.pedido_id = p.id
      WHERE p.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (pedidoRows.isEmpty) return null;

    final productosRows = await db.rawQuery(
      '''
      SELECT i.id,
             i.producto_id,
             i.codigo,
             i.nombre,
             i.presentacion,
             i.equivalencia,
             i.cantidad,
             COALESCE(ci.precio_cotizacion, i.precio_unitario) AS precio_unitario,
             COALESCE(ci.subtotal, i.subtotal) AS subtotal,
             COALESCE(ci.descuento, 0) AS descuento_cotizado,
             COALESCE(ci.tipo_descuento, 'monto') AS tipo_descuento_cotizado,
             pr.marca,
             pr.imagen_path
      FROM pedido_items i
      LEFT JOIN productos pr ON pr.id = i.producto_id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = i.pedido_id
           AND LOWER(co.estado) = 'generada'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      LEFT JOIN cotizacion_items ci
        ON ci.cotizacion_id = cv.id
       AND ci.pedido_item_id = i.id
      WHERE i.pedido_id = ?
      ORDER BY i.nombre ASC
      ''',
      [id],
    );

    final cotizacionesRows = await db.query(
      'cotizaciones',
      where: 'pedido_id = ?',
      whereArgs: [id],
      orderBy: 'creado_en DESC',
    );

    final historialRows = await db.query(
      'pedido_historial',
      where: 'pedido_id = ?',
      whereArgs: [id],
      orderBy: 'creado_en ASC',
    );

    return _pedidoDetalleFromMaps(
      pedidoRows.first,
      productosRows,
      cotizacionesRows,
      historialRows,
    );
  }

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

  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async {
    final db = await _db;
    final rows = await db.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'cotizacion_items',
      where: 'cotizacion_id = ?',
      whereArgs: [id],
      orderBy: 'nombre ASC',
    );
    return _cotizacionGuardadaFromMap(rows.first, itemRows);
  }

  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) async {
    if (cotizacion.items.isEmpty) {
      throw StateError('La cotización no tiene productos.');
    }
    final db = await _db;
    final selected = await db.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [cotizacionId],
      limit: 1,
    );
    if (selected.isEmpty) {
      throw StateError('La cotización seleccionada ya no existe.');
    }
    final selectedState = (selected.first['estado'] as String? ?? '')
        .trim()
        .toLowerCase();

    // Las versiones ya generadas son documentos históricos inmutables.
    // Editarlas crea una nueva versión; solo el borrador se actualiza.
    if (selectedState != 'borrador') {
      return guardarCotizacion(cotizacion);
    }

    final generated = cotizacion.estado.trim().toLowerCase() != 'borrador';
    if (generated &&
        cotizacion.items.any((item) => item.precioCotizacion <= 0)) {
      throw StateError(
        'Todos los productos deben tener un precio válido antes de generar la cotización.',
      );
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      if (generated) {
        await txn.update(
          'cotizaciones',
          {'estado': 'Archivada', 'actualizado_en': now},
          where: "pedido_id = ? AND id <> ? AND LOWER(estado) = 'generada'",
          whereArgs: [cotizacion.pedidoId, cotizacionId],
        );
      }
      await txn.update(
        'cotizaciones',
        {
          'subtotal': cotizacion.subtotal,
          'descuento_global': cotizacion.descuentoGlobal,
          'tipo_descuento_global': cotizacion.tipoDescuentoGlobal,
          'descuento_global_porcentaje': cotizacion.descuentoGlobalPorcentaje,
          'descuento_global_monto': cotizacion.descuentoGlobalMonto,
          'total': cotizacion.total,
          'vigencia_dias': cotizacion.vigenciaDias,
          'condiciones': cotizacion.condiciones,
          'observaciones': cotizacion.observaciones,
          'estado': cotizacion.estado,
          'actualizado_en': now,
        },
        where: 'id = ?',
        whereArgs: [cotizacionId],
      );
      await txn.delete(
        'cotizacion_items',
        where: 'cotizacion_id = ?',
        whereArgs: [cotizacionId],
      );
      await _insertarItemsCotizacion(
        txn,
        cotizacionId: cotizacionId,
        items: cotizacion.items,
      );
      if (generated) {
        await txn.update(
          'pedidos',
          {
            'subtotal_conocido': cotizacion.total,
            'total_parcial': 0,
            'sincronizado': 0,
            'sync_error': null,
          },
          where: 'id = ?',
          whereArgs: [cotizacion.pedidoId],
        );
        final version = selected.first['version'] as int? ?? 1;
        final code = selected.first['codigo'] as String? ?? '';
        await _registrarHistorialPedido(
          txn,
          pedidoId: cotizacion.pedidoId,
          evento: 'Cotización $code vigente • versión $version',
          observacion:
              'Total de cotización: S/ ${cotizacion.total.toStringAsFixed(2)}',
          responsable: null,
          creadoEn: now,
        );
      }
    });
    final updated = await obtenerCotizacion(cotizacionId);
    if (updated == null) {
      throw StateError('No se pudo volver a leer la cotización.');
    }
    return updated;
  }

  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) async {
    if (cotizacion.items.isEmpty) {
      throw StateError('La cotización no tiene productos.');
    }
    final db = await _db;
    return db.transaction((txn) async {
      final pedidoRows = await txn.query(
        'pedidos',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [cotizacion.pedidoId],
        limit: 1,
      );
      if (pedidoRows.isEmpty) {
        throw StateError('El pedido ya no existe.');
      }
      final esGenerada = cotizacion.estado.trim().toLowerCase() != 'borrador';
      if (esGenerada) {
        if (cotizacion.items.any((item) => item.precioCotizacion <= 0)) {
          throw StateError(
            'Todos los productos deben tener un precio válido antes de generar la cotización.',
          );
        }
        final cantidadItemsPedido =
            Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM pedido_items WHERE pedido_id = ?',
                [cotizacion.pedidoId],
              ),
            ) ??
            0;
        final idsCotizados = cotizacion.items
            .map((item) => item.pedidoItemId)
            .toSet();
        if (idsCotizados.length != cantidadItemsPedido) {
          throw StateError(
            'La cotización debe incluir todos los productos del pedido.',
          );
        }
      }

      final now = DateTime.now();
      final anteriores = await txn.query(
        'cotizaciones',
        columns: ['codigo', 'codigo_base', 'version'],
        where: 'pedido_id = ?',
        whereArgs: [cotizacion.pedidoId],
        orderBy: 'version DESC, creado_en DESC',
        limit: 1,
      );
      late final String codigoBase;
      late final String codigoPersistido;
      late final int version;
      if (anteriores.isEmpty) {
        final codigosRows = await txn.query(
          'cotizaciones',
          columns: ['codigo', 'codigo_base'],
          where: 'codigo LIKE ? OR codigo_base LIKE ?',
          whereArgs: ['COT-${now.year}-%', 'COT-${now.year}-%'],
        );
        codigoBase = CotizacionCodigo.siguiente(
          year: now.year,
          codigosExistentes: codigosRows.expand(
            (row) => [row['codigo'] as String?, row['codigo_base'] as String?],
          ),
        );
        codigoPersistido = codigoBase;
        version = 1;
      } else {
        final anterior = anteriores.first;
        final baseGuardada = anterior['codigo_base'] as String? ?? '';
        codigoBase = baseGuardada.trim().isEmpty
            ? anterior['codigo'] as String
            : baseGuardada;
        version = (anterior['version'] as int? ?? 1) + 1;
        codigoPersistido = '$codigoBase-V$version';
      }
      final cotizacionId = const Uuid().v4();
      final nowIso = now.toIso8601String();
      if (esGenerada) {
        await txn.update(
          'cotizaciones',
          {'estado': 'Archivada', 'actualizado_en': nowIso},
          where: "pedido_id = ? AND LOWER(estado) = 'generada'",
          whereArgs: [cotizacion.pedidoId],
        );
      }
      await txn.insert('cotizaciones', {
        'id': cotizacionId,
        'pedido_id': cotizacion.pedidoId,
        'codigo': codigoPersistido,
        'codigo_base': codigoBase,
        'version': version,
        'subtotal': cotizacion.subtotal,
        'descuento_global': cotizacion.descuentoGlobal,
        'tipo_descuento_global': cotizacion.tipoDescuentoGlobal,
        'descuento_global_porcentaje': cotizacion.descuentoGlobalPorcentaje,
        'descuento_global_monto': cotizacion.descuentoGlobalMonto,
        'total': cotizacion.total,
        'vigencia_dias': cotizacion.vigenciaDias,
        'condiciones': cotizacion.condiciones,
        'observaciones': cotizacion.observaciones,
        'estado': cotizacion.estado,
        'creado_en': nowIso,
        'actualizado_en': nowIso,
      });
      await _insertarItemsCotizacion(
        txn,
        cotizacionId: cotizacionId,
        items: cotizacion.items,
      );
      if (esGenerada) {
        await txn.update(
          'pedidos',
          {
            'subtotal_conocido': cotizacion.total,
            'total_parcial': 0,
            'sincronizado': 0,
            'sync_error': null,
          },
          where: 'id = ?',
          whereArgs: [cotizacion.pedidoId],
        );
        await _registrarHistorialPedido(
          txn,
          pedidoId: cotizacion.pedidoId,
          evento: 'Cotización $codigoPersistido vigente • versión $version',
          observacion:
              'Total de cotización: S/ ${cotizacion.total.toStringAsFixed(2)}',
          responsable: null,
          creadoEn: nowIso,
        );
      }
      final descuentosProductos = cotizacion.items.fold<double>(
        0,
        (total, item) =>
            total +
            (item.precioCotizacion * item.cantidad - item.subtotal).clamp(
              0,
              double.infinity,
            ),
      );
      final descuentoTotal = descuentosProductos + cotizacion.descuentoGlobal;
      return CotizacionPedidoGuardada(
        id: cotizacionId,
        pedidoId: cotizacion.pedidoId,
        codigo: codigoBase,
        total: cotizacion.total,
        creadoEn: now,
        version: version,
        estado: cotizacion.estado,
        subtotalProductos: cotizacion.subtotal,
        descuento: descuentoTotal,
        totalSinIgv: CotizacionIgv.totalSinIgv(cotizacion.total),
        igv: CotizacionIgv.igvIncluido(cotizacion.total),
      );
    });
  }

  Future<void> registrarPdfCotizacion({
    required String cotizacionId,
    required String pdfPath,
  }) async {
    await (await _db).update(
      'cotizaciones',
      {'pdf_path': pdfPath, 'actualizado_en': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [cotizacionId],
    );
  }

  Future<List<ProductoConsolidado>> obtenerProductosConsolidados() async {
    final rows = await _obtenerItemsPreparacionRows();
    final grupos = <String, _ProductoConsolidadoBuilder>{};
    for (final row in rows) {
      final productoId = row['producto_id'] as String? ?? '';
      final codigo = row['item_codigo'] as String? ?? '';
      final nombre = row['item_nombre'] as String? ?? '';
      final presentacion = row['unidad_base'] as String? ?? 'UND';
      final equivalencia = row['equivalencia'] as String? ?? '';
      final variante = _varianteFromJson(row['atributos_json'] as String?);
      final identidad = productoId.isEmpty ? codigo : productoId;
      final key = '$identidad|$codigo|$variante';
      final builder = grupos.putIfAbsent(
        key,
        () => _ProductoConsolidadoBuilder(
          key: key,
          productoId: productoId,
          codigo: codigo,
          nombre: nombre,
          marca: row['marca'] as String?,
          empresa: row['empresa'] as String?,
          categoria: row['categoria'] as String?,
          subcategoria: row['subcategoria'] as String?,
          variante: variante,
          presentacion: presentacion,
          equivalencia: equivalencia,
          unidadBase: presentacion,
          pendientePrecio: row['precio_unitario'] == null,
          imagenPath: row['imagen_path'] as String?,
        ),
      );
      if (row['precio_unitario'] == null) builder.pendientePrecio = true;
      final solicitada = row['cantidad_base_requerida'] as int? ?? 0;
      final preparada = _clampPreparada(
        (row['cantidad_preparada'] as num? ?? 0).toInt(),
        solicitada,
      );
      builder
        ..totalRequerido += solicitada
        ..totalPreparado += preparada
        ..distribucion.add(
          DistribucionPedido(
            pedidoItemId: row['item_id'] as String,
            pedidoId: row['pedido_id'] as String,
            codigoPedido: row['pedido_codigo'] as String? ?? '',
            cliente: row['cliente_nombre'] as String? ?? '',
            telefono: row['telefono'] as String? ?? '',
            cantidadSolicitada: solicitada,
            cantidadPreparada: preparada,
            fecha:
                DateTime.tryParse(row['pedido_fecha'] as String? ?? '') ??
                DateTime.now(),
            estadoPedido: row['pedido_estado'] as String? ?? '',
            hojaCodigo: row['hoja_codigo'] as String? ?? '',
            clienteId: row['cliente_id'] as String? ?? '',
            presentacion: row['presentacion'] as String? ?? '',
            equivalencia: equivalencia,
            cantidadOriginal: row['cantidad'] as int? ?? 0,
            unidadBase: presentacion,
            sinPrecio: row['precio_unitario'] == null,
          ),
        );
    }
    final disponiblesRows = await (await _db).rawQuery('''
      SELECT producto_key,
             presentacion,
             equivalencia,
             factor_unidad_base,
             SUM(cantidad_delta) AS cantidad_disponible
      FROM preparacion_disponible_movimientos
      GROUP BY producto_key, presentacion, equivalencia, factor_unidad_base
      HAVING SUM(cantidad_delta) > 0
    ''');
    for (final row in disponiblesRows) {
      final builder = grupos[row['producto_key'] as String? ?? ''];
      if (builder == null) continue;
      builder.disponibles.add(
        PreparacionDisponible(
          presentacion: row['presentacion'] as String? ?? 'Unidad',
          equivalencia: row['equivalencia'] as String? ?? '',
          factorUnidadBase: row['factor_unidad_base'] as int? ?? 1,
          cantidad: (row['cantidad_disponible'] as num? ?? 0).toInt(),
        ),
      );
    }
    final productos = grupos.values.map((builder) => builder.build()).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return productos;
  }

  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() async {
    final rows = await _obtenerItemsPreparacionRows(soloHojaActiva: true);
    final grupos = <String, _PedidoPreparacionBuilder>{};
    for (final row in rows) {
      final pedidoId = row['pedido_id'] as String;
      final builder = grupos.putIfAbsent(pedidoId, () {
        final estadoPedido = row['pedido_estado'] as String? ?? '';
        final estadoNormalizado = _normalizarEstadoPedido(estadoPedido);
        final operacionCerrada =
            estadoNormalizado == 'listo' || estadoNormalizado == 'entregado';
        return _PedidoPreparacionBuilder(
          id: pedidoId,
          codigo: row['pedido_codigo'] as String? ?? '',
          cliente: row['cliente_nombre'] as String? ?? '',
          telefono: row['telefono'] as String? ?? '',
          direccion: row['direccion'] as String? ?? '',
          referencia: row['referencia'] as String? ?? '',
          fecha:
              DateTime.tryParse(row['pedido_fecha'] as String? ?? '') ??
              DateTime.now(),
          estadoPedido: estadoPedido,
          estadoCarga: operacionCerrada || (row['carga_id'] as String?) != null
              ? 'cargado'
              : 'pendiente_carga',
          paquetes: row['paquetes'] as int? ?? 0,
        );
      });
      final solicitada = row['cantidad_base_requerida'] as int? ?? 0;
      final preparada = _clampPreparada(
        (row['cantidad_preparada'] as num? ?? 0).toInt(),
        solicitada,
      );
      final marca = row['marca'] as String? ?? '';
      final empresa = row['empresa'] as String? ?? '';
      final categoria = row['categoria'] as String? ?? '';
      final cantidadPresentaciones = row['cantidad'] as int? ?? 0;
      final factorUnidadBase = row['factor_unidad_base'] as int? ?? 1;
      final preparadaPresentaciones = factorUnidadBase <= 0
          ? 0
          : (preparada ~/ factorUnidadBase).clamp(0, cantidadPresentaciones);
      builder.registrarClasificacion(empresa: empresa, categoria: categoria);
      builder.productos.add(
        ProductoPreparacion(
          pedidoItemId: row['item_id'] as String,
          productoId: row['producto_id'] as String? ?? '',
          codigo: row['item_codigo'] as String? ?? '',
          nombre: row['item_nombre'] as String? ?? '',
          presentacion: row['presentacion'] as String? ?? 'Unidad',
          equivalencia: row['equivalencia'] as String? ?? '',
          cantidadSolicitada: cantidadPresentaciones,
          cantidadPreparada: preparadaPresentaciones,
          marca: marca,
          empresa: empresa,
          categoria: categoria,
          variante: _varianteFromJson(row['atributos_json'] as String?),
          imagenPath: row['imagen_path'] as String?,
          factorUnidadBase: factorUnidadBase,
          unidadBase: row['unidad_base'] as String? ?? 'UND',
          cantidadSolicitadaBase: solicitada,
          cantidadPreparadaBase: preparada,
        ),
      );
    }
    final pedidos = grupos.values.map((builder) => builder.build()).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return pedidos;
  }

  Future<void> registrarPreparacionProducto(
    PreparacionProductoDraft preparacion,
  ) async {
    if (preparacion.asignaciones.isEmpty &&
        preparacion.movimientosDisponibles.isEmpty) {
      return;
    }
    final db = await _db;
    await db.transaction((txn) async {
      if (preparacion.requierePedidosCompletos &&
          preparacion.asignaciones.isNotEmpty) {
        await _validarAsignacionesCompletas(txn, preparacion.asignaciones);
      }
      final pedidosAfectados = <String>{};
      for (final movimiento in preparacion.movimientosDisponibles) {
        if (movimiento.cantidadDelta == 0) continue;
        final stockRows = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(cantidad_delta), 0) AS disponible
          FROM preparacion_disponible_movimientos
          WHERE producto_key = ?
            AND LOWER(presentacion) = LOWER(?)
            AND factor_unidad_base = ?
          ''',
          [
            preparacion.productoKey,
            movimiento.presentacion,
            movimiento.factorUnidadBase,
          ],
        );
        final disponible = (stockRows.first['disponible'] as num? ?? 0).toInt();
        if (disponible + movimiento.cantidadDelta < 0) {
          throw StateError(
            'No hay suficientes ${movimiento.presentacion} disponibles.',
          );
        }
        await txn.insert('preparacion_disponible_movimientos', {
          'id': const Uuid().v4(),
          'producto_key': preparacion.productoKey,
          'producto_id': movimiento.productoId,
          'presentacion': movimiento.presentacion,
          'equivalencia': movimiento.equivalencia,
          'factor_unidad_base': movimiento.factorUnidadBase,
          'cantidad_delta': movimiento.cantidadDelta,
          'cantidad_base_delta':
              movimiento.cantidadDelta * movimiento.factorUnidadBase,
          'observacion': preparacion.observacion,
          'creado_en': DateTime.now().toIso8601String(),
        });
      }
      for (final asignacion in preparacion.asignaciones) {
        if (asignacion.cantidad <= 0) continue;
        final itemRows = await txn.rawQuery(
          '''
          SELECT i.cantidad AS cantidad_presentaciones,
                 i.factor_unidad_base,
                 i.cantidad * i.factor_unidad_base AS cantidad_base_requerida,
                  COALESCE(SUM(pp.cantidad_base), 0) AS preparada
          FROM pedido_items i
          INNER JOIN pedidos p ON p.id = i.pedido_id
          INNER JOIN hojas_pedido h ON h.id = p.hoja_id
          LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
          WHERE i.id = ?
            AND h.activa = 1
            AND h.estado = 'Abierta'
            AND LOWER(p.estado) NOT IN (
              'cancelado',
              'listo para entregar',
              'entregado'
            )
          GROUP BY i.id
          ''',
          [asignacion.pedidoItemId],
        );
        if (itemRows.isEmpty) {
          throw StateError(
            'El producto ya no pertenece al flujo operativo de la hoja activa.',
          );
        }
        final solicitada =
            itemRows.first['cantidad_base_requerida'] as int? ?? 0;
        final preparada = (itemRows.first['preparada'] as num? ?? 0).toInt();
        final factor = itemRows.first['factor_unidad_base'] as int? ?? 1;
        final solicitadaPresentaciones =
            itemRows.first['cantidad_presentaciones'] as int? ?? 0;
        final preparadaPresentaciones = factor <= 0
            ? 0
            : (preparada ~/ factor).clamp(0, solicitadaPresentaciones);
        final pendientePresentaciones =
            solicitadaPresentaciones - preparadaPresentaciones;
        if (asignacion.cantidad > pendientePresentaciones) {
          throw StateError(
            'La cantidad preparada supera las presentaciones pendientes.',
          );
        }
        final pendienteBase = solicitada - preparada;
        final cantidadBase = (asignacion.cantidad * factor).clamp(
          0,
          pendienteBase,
        );
        await txn.insert('preparacion_productos', {
          'id': const Uuid().v4(),
          'pedido_item_id': asignacion.pedidoItemId,
          'pedido_id': asignacion.pedidoId,
          'producto_id': asignacion.productoId,
          'cantidad': asignacion.cantidad,
          'cantidad_base': cantidadBase,
          'observacion': preparacion.observacion,
          'creado_en': DateTime.now().toIso8601String(),
        });
        pedidosAfectados.add(asignacion.pedidoId);
      }
      for (final pedidoId in pedidosAfectados) {
        await _actualizarEstadoPedidoPorPreparacion(txn, pedidoId);
      }
    });
  }

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

  Future<List<ClientePedido>> buscarClientes(String query) async {
    final text = query.trim();
    final rows = await (await _db).query(
      'clientes',
      where: text.isEmpty
          ? null
          : 'nombre LIKE ? OR telefono LIKE ? OR dni LIKE ? OR ruc LIKE ?',
      whereArgs: text.isEmpty
          ? null
          : List.filled(4, '%$text%', growable: false),
      orderBy: 'nombre',
      limit: 30,
    );
    return rows.map(_clienteFromMap).toList();
  }

  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async {
    if (items.isEmpty) throw StateError('El carrito está vacío.');
    final db = await _db;
    return db.transaction((txn) async {
      final hojaRows = await txn.query(
        'hojas_pedido',
        where: "id = ? AND activa = 1 AND estado = 'Abierta'",
        whereArgs: [hoja.id],
        limit: 1,
      );
      if (hojaRows.isEmpty) {
        throw StateError('La hoja de pedido ya no está activa.');
      }

      final clienteId = await _obtenerOCrearCliente(txn, cliente);
      final now = DateTime.now();
      final count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM pedidos WHERE creado_en LIKE ?',
              ['${now.year}-%'],
            ),
          ) ??
          0;
      final codigo =
          'PED-${now.year}-${(count + 1).toString().padLeft(4, '0')}';
      final pedidoId = const Uuid().v4();
      final subtotal = items.fold<double>(
        0,
        (total, item) => total + (item.subtotal ?? 0),
      );
      final parcial = items.any((item) => item.precioUnitario == null);
      await txn.insert('pedidos', {
        'id': pedidoId,
        'codigo': codigo,
        'hoja_id': hoja.id,
        'cliente_id': clienteId,
        'vendedor': vendedor,
        'estado': 'Pendiente',
        'subtotal_conocido': subtotal,
        'total_parcial': parcial ? 1 : 0,
        'sincronizado': 0,
        'sync_error': null,
        'creado_en': now.toIso8601String(),
      });
      for (final item in items) {
        await txn.insert('pedido_items', {
          'id': const Uuid().v4(),
          'pedido_id': pedidoId,
          'producto_id': item.productoId,
          'codigo': item.codigo,
          'nombre': item.nombre,
          'presentacion': item.presentacion,
          'equivalencia': item.equivalencia,
          'cantidad': item.cantidad,
          'factor_unidad_base': _factorUnidadBase(
            item.presentacion,
            item.equivalencia,
          ),
          'unidad_base': _unidadBase(item.presentacion, item.equivalencia),
          'precio_unitario': item.precioUnitario,
          'subtotal': item.subtotal,
        });
      }
      return PedidoRegistrado(
        id: pedidoId,
        codigo: codigo,
        cliente: cliente.nombre,
        hojaCodigo: hoja.codigo,
        estado: 'Pendiente',
      );
    });
  }

  Future<String> _obtenerOCrearCliente(
    Transaction txn,
    ClientePedido cliente,
  ) async {
    if (cliente.id != null) return cliente.id!;
    final matches = await txn.query(
      'clientes',
      columns: ['id'],
      where: 'telefono = ? OR (dni != ? AND dni = ?) OR (ruc != ? AND ruc = ?)',
      whereArgs: [cliente.telefono, '', cliente.dni, '', cliente.ruc],
      limit: 1,
    );
    if (matches.isNotEmpty) return matches.first['id'] as String;
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await txn.insert('clientes', {
      'id': id,
      'nombre': cliente.nombre,
      'tipo': cliente.ruc.trim().isEmpty ? 'Persona' : 'Empresa',
      'telefono': cliente.telefono,
      'dni': cliente.dni,
      'ruc': cliente.ruc,
      'tipo_entrega': 'entrega',
      'direccion': cliente.direccion,
      'referencia': cliente.referencia,
      'foto_ubicacion_path': cliente.fotoUbicacionPath,
      'activo': 1,
      'observaciones': cliente.observaciones,
      'creado_en': now,
      'actualizado_en': now,
    });
    return id;
  }

  ClientePedido _clienteFromMap(Map<String, Object?> row) => ClientePedido(
    id: row['id'] as String,
    nombre: row['nombre'] as String,
    telefono: row['telefono'] as String,
    dni: row['dni'] as String,
    ruc: row['ruc'] as String,
    tipoEntrega: 'entrega',
    direccion: row['direccion'] as String,
    referencia: row['referencia'] as String,
    fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
    observaciones: row['observaciones'] as String,
  );

  PedidoResumen _pedidoResumenFromMap(Map<String, Object?> row) {
    final productosRaw = row['productos_resumen'] as String?;
    final productos = (productosRaw == null || productosRaw.isEmpty)
        ? const <String>[]
        : productosRaw
              .split('|||')
              .where((producto) => producto.trim().isNotEmpty)
              .toSet()
              .toList();
    return PedidoResumen(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      fecha:
          DateTime.tryParse(row['creado_en'] as String? ?? '') ??
          DateTime.now(),
      estado: row['estado'] as String? ?? 'Pendiente',
      sincronizado: (row['sincronizado'] as int? ?? 0) == 1,
      guardadoLocal: true,
      clienteId: row['cliente_id'] as String,
      clienteNombre: row['cliente_nombre'] as String? ?? '',
      telefono: row['telefono'] as String? ?? '',
      dni: row['dni'] as String? ?? '',
      ruc: row['ruc'] as String? ?? '',
      direccion: row['direccion'] as String? ?? '',
      referencia: row['referencia'] as String? ?? '',
      fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
      cantidadProductos: row['cantidad_productos'] as int? ?? 0,
      cantidadPresentaciones: row['cantidad_presentaciones'] as int? ?? 0,
      productosResumen: productos,
      subtotalConocido: (row['subtotal_conocido'] as num? ?? 0).toDouble(),
      productosSinPrecio: row['productos_sin_precio'] as int? ?? 0,
      hojaCodigo: row['hoja_codigo'] as String? ?? '',
      vendedor: row['vendedor'] as String? ?? '',
      empresas: _splitCsv(row['empresas'] as String?),
      marcas: _splitCsv(row['marcas'] as String?),
      categorias: _splitCsv(row['categorias'] as String?),
      cotizacionesGeneradas: row['cotizaciones_generadas'] as int? ?? 0,
      cotizacionVigente: row['cotizacion_vigente_id'] != null,
      subtotalProductos: (row['cotizacion_subtotal_productos'] as num? ?? 0)
          .toDouble(),
      descuentoCotizado: (row['cotizacion_descuento'] as num? ?? 0).toDouble(),
      totalSinIgv: CotizacionIgv.totalSinIgv(
        (row['cotizacion_total'] as num? ?? 0).toDouble(),
      ),
      igv: CotizacionIgv.igvIncluido(
        (row['cotizacion_total'] as num? ?? 0).toDouble(),
      ),
      totalCotizado: (row['cotizacion_total'] as num? ?? 0).toDouble(),
      syncError: row['sync_error'] as String?,
    );
  }

  List<String> _splitCsv(String? value) => value == null || value.isEmpty
      ? const []
      : value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();

  Future<void> _insertarItemsCotizacion(
    Transaction txn, {
    required String cotizacionId,
    required List<CotizacionPedidoItemDraft> items,
  }) async {
    for (final item in items) {
      await txn.insert('cotizacion_items', {
        'id': const Uuid().v4(),
        'cotizacion_id': cotizacionId,
        'pedido_item_id': item.pedidoItemId,
        'producto_id': item.productoId,
        'codigo': item.codigo,
        'nombre': item.nombre,
        'presentacion': item.presentacion,
        'cantidad': item.cantidad,
        'precio_cotizacion': item.precioCotizacion,
        'descuento': item.descuento,
        'tipo_descuento': item.tipoDescuento,
        'precio_final': item.precioFinal,
        'subtotal': item.subtotal,
      });
    }
  }

  CotizacionPedidoGuardada _cotizacionGuardadaFromMap(
    Map<String, Object?> row,
    List<Map<String, Object?>> itemRows,
  ) {
    final total = (row['total'] as num? ?? 0).toDouble();
    final subtotal = (row['subtotal'] as num? ?? 0).toDouble();
    final global = (row['descuento_global'] as num? ?? 0).toDouble();
    final items = itemRows
        .map(
          (item) => CotizacionPedidoItemGuardado(
            id: item['id'] as String,
            pedidoItemId: item['pedido_item_id'] as String,
            productoId: item['producto_id'] as String,
            codigo: item['codigo'] as String? ?? '',
            nombre: item['nombre'] as String? ?? '',
            presentacion: item['presentacion'] as String? ?? '',
            cantidad: item['cantidad'] as int? ?? 0,
            precioCotizacion: (item['precio_cotizacion'] as num? ?? 0)
                .toDouble(),
            descuento: (item['descuento'] as num? ?? 0).toDouble(),
            tipoDescuento: item['tipo_descuento'] as String? ?? 'monto',
            precioFinal: (item['precio_final'] as num? ?? 0).toDouble(),
            subtotal: (item['subtotal'] as num? ?? 0).toDouble(),
          ),
        )
        .toList();
    final itemDiscounts = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.precioCotizacion * item.cantidad - item.subtotal)
              .clamp(0, double.infinity)
              .toDouble(),
    );
    return CotizacionPedidoGuardada(
      id: row['id'] as String,
      pedidoId: row['pedido_id'] as String,
      codigo: (row['codigo_base'] as String? ?? '').trim().isEmpty
          ? row['codigo'] as String
          : row['codigo_base'] as String,
      total: total,
      creadoEn:
          DateTime.tryParse(row['creado_en'] as String? ?? '') ??
          DateTime.now(),
      pdfPath: row['pdf_path'] as String?,
      version: row['version'] as int? ?? 1,
      estado: row['estado'] as String? ?? 'Generada',
      subtotalProductos: subtotal,
      descuento: itemDiscounts + global,
      totalSinIgv: CotizacionIgv.totalSinIgv(total),
      igv: CotizacionIgv.igvIncluido(total),
      vigenciaDias: row['vigencia_dias'] as int? ?? 7,
      condiciones: row['condiciones'] as String? ?? '',
      observaciones: row['observaciones'] as String? ?? '',
      descuentoGlobalPorcentaje:
          (row['descuento_global_porcentaje'] as num? ?? 0).toDouble(),
      descuentoGlobalMonto: (row['descuento_global_monto'] as num? ?? 0)
          .toDouble(),
      items: items,
    );
  }

  PedidoDetalle _pedidoDetalleFromMaps(
    Map<String, Object?> row,
    List<Map<String, Object?>> productosRows,
    List<Map<String, Object?>> cotizacionesRows,
    List<Map<String, Object?>> historialRows,
  ) {
    final fecha =
        DateTime.tryParse(row['creado_en'] as String? ?? '') ?? DateTime.now();
    final productos = productosRows.map(_pedidoDetalleProductoFromMap).toList();
    final cotizacionVigente = row['cotizacion_vigente_id'] != null;
    final productosSinPrecio = cotizacionVigente
        ? 0
        : productos.where((producto) => !producto.tienePrecio).length;
    final subtotalConocido = (row['subtotal_conocido'] as num? ?? 0).toDouble();
    final vendedor = row['vendedor'] as String? ?? '';
    final cotizacionesGeneradas =
        cotizacionesRows
            .where(
              (cotizacion) =>
                  (cotizacion['estado'] as String? ?? '').toLowerCase() !=
                  'borrador',
            )
            .toList()
          ..sort((a, b) {
            final versionA = a['version'] as int? ?? 1;
            final versionB = b['version'] as int? ?? 1;
            return versionB.compareTo(versionA);
          });
    final ultimaCotizacion = cotizacionesGeneradas.isEmpty
        ? null
        : cotizacionesGeneradas.first;
    final cotizaciones = cotizacionesRows
        .map((quote) => _cotizacionGuardadaFromMap(quote, const []))
        .toList();
    final historial = [
      PedidoHistorialEntrada(
        fecha: fecha,
        evento: 'Pedido registrado',
        responsable: vendedor.isEmpty ? null : vendedor,
      ),
      ...cotizacionesGeneradas
          .where((cotizacion) {
            final codigo = cotizacion['codigo'] as String? ?? '';
            return !historialRows.any(
              (entrada) =>
                  (entrada['evento'] as String? ?? '').contains(codigo),
            );
          })
          .map((cotizacion) {
            final cotizacionFecha =
                DateTime.tryParse(cotizacion['creado_en'] as String? ?? '') ??
                fecha;
            final codigo = cotizacion['codigo'] as String? ?? '';
            final total = (cotizacion['total'] as num? ?? 0).toDouble();
            return PedidoHistorialEntrada(
              fecha: cotizacionFecha,
              evento:
                  'Cotización $codigo generada\nTotal: S/ ${total.toStringAsFixed(2)}',
              responsable: vendedor.isEmpty ? null : vendedor,
            );
          }),
      ...historialRows.map((entrada) {
        final entradaFecha =
            DateTime.tryParse(entrada['creado_en'] as String? ?? '') ?? fecha;
        final observacion = (entrada['observacion'] as String? ?? '')
            .replaceAll(' — incluye IGV', '')
            .replaceAll(' - incluye IGV', '');
        final evento = (entrada['evento'] as String? ?? '')
            .replaceAll(' — incluye IGV', '')
            .replaceAll(' - incluye IGV', '');
        return PedidoHistorialEntrada(
          fecha: entradaFecha,
          evento: observacion.trim().isEmpty ? evento : '$evento\n$observacion',
          responsable: entrada['responsable'] as String?,
        );
      }),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));

    return PedidoDetalle(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      fecha: fecha,
      estado: row['estado'] as String? ?? 'Pendiente',
      sincronizado: (row['sincronizado'] as int? ?? 0) == 1,
      guardadoLocal: true,
      clienteId: row['cliente_id'] as String,
      clienteNombre: row['cliente_nombre'] as String? ?? '',
      telefono: row['telefono'] as String? ?? '',
      clienteDni: row['dni'] as String? ?? '',
      clienteRuc: row['ruc'] as String? ?? '',
      direccion: row['direccion'] as String? ?? '',
      referencia: row['referencia'] as String? ?? '',
      fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
      observacionesEntrega: row['observaciones'] as String? ?? '',
      productos: productos,
      subtotalConocido: subtotalConocido,
      productosSinPrecio: productosSinPrecio,
      hoja: row['hoja_codigo'] as String? ?? '',
      vendedor: vendedor,
      cotizacionCodigo: ultimaCotizacion == null
          ? null
          : ((ultimaCotizacion['codigo_base'] as String? ?? '').trim().isEmpty
                ? ultimaCotizacion['codigo'] as String?
                : ultimaCotizacion['codigo_base'] as String?),
      cotizacionTotal: (row['cotizacion_total'] as num?)?.toDouble(),
      cotizaciones: cotizaciones,
      cotizacionVigente: cotizacionVigente,
      subtotalProductos: (row['cotizacion_subtotal_productos'] as num? ?? 0)
          .toDouble(),
      descuentosProductos:
          ((row['cotizacion_subtotal_productos'] as num? ?? 0).toDouble() -
                  (row['cotizacion_subtotal_neto_productos'] as num? ?? 0)
                      .toDouble())
              .clamp(0, double.infinity)
              .toDouble(),
      descuentoGlobalCotizacion:
          (row['cotizacion_descuento_global'] as num? ?? 0).toDouble(),
      descuentoGlobalPorcentaje:
          (row['descuento_global_porcentaje'] as num? ?? 0).toDouble(),
      descuentoGlobalMonto: (row['descuento_global_monto'] as num? ?? 0)
          .toDouble(),
      totalSinIgv: CotizacionIgv.totalSinIgv(
        (row['cotizacion_total'] as num? ?? 0).toDouble(),
      ),
      igv: CotizacionIgv.igvIncluido(
        (row['cotizacion_total'] as num? ?? 0).toDouble(),
      ),
      observacionesCotizacion: row['cotizacion_observaciones'] as String? ?? '',
      syncError: row['sync_error'] as String?,
      estadoPreparacion: (row['preparacion_completa'] as int? ?? 0) == 1
          ? 'completa'
          : (row['tiene_preparacion'] as int? ?? 0) == 1
          ? 'parcial'
          : 'pendiente',
      estadoCarga: (row['carga_completa'] as int? ?? 0) == 1
          ? 'cargado'
          : 'pendiente',
      historial: historial,
    );
  }

  PedidoDetalleProducto _pedidoDetalleProductoFromMap(
    Map<String, Object?> row,
  ) => PedidoDetalleProducto(
    id: row['id'] as String,
    productoId: row['producto_id'] as String,
    codigo: row['codigo'] as String? ?? '',
    nombre: row['nombre'] as String? ?? '',
    presentacion: row['presentacion'] as String? ?? '',
    equivalencia: row['equivalencia'] as String? ?? '',
    cantidad: row['cantidad'] as int? ?? 0,
    precioUnitario: (row['precio_unitario'] as num?)?.toDouble(),
    subtotal: (row['subtotal'] as num?)?.toDouble(),
    marca: row['marca'] as String?,
    imagenPath: row['imagen_path'] as String?,
    descuentoCotizado: (row['descuento_cotizado'] as num? ?? 0).toDouble(),
    tipoDescuentoCotizado: row['tipo_descuento_cotizado'] as String? ?? 'monto',
  );

  Future<List<Map<String, Object?>>> _obtenerItemsPreparacionRows({
    bool soloHojaActiva = false,
  }) async => (await _db).rawQuery('''
        SELECT i.id AS item_id,
               i.pedido_id,
               i.producto_id,
               i.codigo AS item_codigo,
               i.nombre AS item_nombre,
               i.presentacion,
               i.equivalencia,
               i.cantidad,
               i.factor_unidad_base,
               i.unidad_base,
               i.cantidad * i.factor_unidad_base AS cantidad_base_requerida,
               p.codigo AS pedido_codigo,
               h.codigo AS hoja_codigo,
               p.creado_en AS pedido_fecha,
               p.estado AS pedido_estado,
               c.nombre AS cliente_nombre,
               c.id AS cliente_id,
               c.telefono,
               c.direccion,
               c.referencia,
               pr.marca,
               pr.empresa,
               pr.categoria,
               pr.subcategoria,
               pr.atributos_json,
               pr.imagen_path,
               COALESCE(ci.precio_cotizacion, i.precio_unitario) AS precio_unitario,
               CASE
                 WHEN LOWER(p.estado) LIKE 'listo%'
                   OR LOWER(p.estado) = 'entregado'
                 THEN i.cantidad * i.factor_unidad_base
                 ELSE COALESCE(SUM(pp.cantidad_base), 0)
               END AS cantidad_preparada,
               pc.id AS carga_id,
               pc.paquetes
        FROM pedido_items i
        INNER JOIN pedidos p ON p.id = i.pedido_id
        INNER JOIN hojas_pedido h ON h.id = p.hoja_id
        INNER JOIN clientes c ON c.id = p.cliente_id
        LEFT JOIN productos pr ON pr.id = i.producto_id
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
        LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
        LEFT JOIN pedido_cargas pc ON pc.pedido_id = p.id
        WHERE LOWER(p.estado) <> 'cancelado'
          ${soloHojaActiva ? "AND h.activa = 1 AND h.estado = 'Abierta'" : ''}
        GROUP BY i.id
        ORDER BY p.creado_en ASC, i.nombre ASC
      ''');

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

  int _clampPreparada(int preparada, int solicitada) {
    if (preparada < 0) return 0;
    if (preparada > solicitada) return solicitada;
    return preparada;
  }

  Future<void> _validarAsignacionesCompletas(
    Transaction txn,
    List<PreparacionProductoAsignacion> asignaciones,
  ) async {
    final grupos = <String, List<PreparacionProductoAsignacion>>{};
    for (final asignacion in asignaciones) {
      final key = '${asignacion.pedidoId}|${asignacion.productoId}';
      grupos.putIfAbsent(key, () => []).add(asignacion);
    }

    for (final grupo in grupos.values) {
      final referencia = grupo.first;
      final rows = await txn.rawQuery(
        '''
        SELECT i.id,
               i.cantidad,
               i.factor_unidad_base,
               COALESCE(SUM(pp.cantidad_base), 0) AS preparada
        FROM pedido_items i
        LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
        WHERE i.pedido_id = ?
          AND i.producto_id = ?
        GROUP BY i.id
        ''',
        [referencia.pedidoId, referencia.productoId],
      );
      final porItem = {
        for (final asignacion in grupo)
          asignacion.pedidoItemId: asignacion.cantidad,
      };
      for (final row in rows) {
        final solicitada = row['cantidad'] as int? ?? 0;
        final factor = row['factor_unidad_base'] as int? ?? 1;
        final preparadaBase = (row['preparada'] as num? ?? 0).toInt();
        final preparadaPresentaciones = factor <= 0
            ? 0
            : (preparadaBase ~/ factor).clamp(0, solicitada);
        final pendiente = solicitada - preparadaPresentaciones;
        if (pendiente <= 0) continue;
        final asignada = porItem[row['id'] as String] ?? 0;
        if (asignada != pendiente) {
          throw StateError(
            'Para clasificar un pedido deben completarse todas las '
            'presentaciones pendientes del producto.',
          );
        }
      }
    }
  }

  String _varianteFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Producto único';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 'Producto único';
      final valores = decoded.entries
          .where((entry) => entry.value.toString().trim().isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList();
      return valores.isEmpty ? 'Producto único' : valores.join(' • ');
    } catch (_) {
      return 'Producto único';
    }
  }

  int _factorUnidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toLowerCase();
    final coincidencias = RegExp(r'(\d+)').allMatches(equivalencia).toList();
    final numero = coincidencias.isEmpty ? null : coincidencias.last.group(1);
    final parsed = int.tryParse(numero ?? '');
    if (parsed != null && parsed > 0) return parsed;
    if (texto.contains('millar')) return 1000;
    if (texto.contains('ciento')) return 100;
    if (texto.contains('docena')) return 12;
    if (texto.contains('par')) return 2;
    return 1;
  }

  String _unidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toUpperCase();
    if (texto.contains('KG')) return 'KG';
    if (texto.contains('LT') || texto.contains('LITRO')) return 'LT';
    if (texto.contains('MT') || texto.contains('METRO')) return 'MT';
    return 'UND';
  }

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

  Future<void> _registrarHistorialPedido(
    Transaction txn, {
    required String pedidoId,
    required String evento,
    required String observacion,
    required String? responsable,
    required String creadoEn,
  }) async {
    await txn.insert('pedido_historial', {
      'id': const Uuid().v4(),
      'pedido_id': pedidoId,
      'evento': evento,
      'observacion': observacion.trim(),
      'responsable': responsable?.trim().isEmpty ?? true ? null : responsable,
      'creado_en': creadoEn,
    });
  }

  String _normalizarEstadoPedido(String estado) {
    final value = estado.trim().toLowerCase();
    if (value.contains('proceso')) return 'en_proceso';
    if (value.contains('listo')) return 'listo';
    if (value.contains('entregado')) return 'entregado';
    if (value.contains('cancelado')) return 'cancelado';
    return 'pendiente';
  }

  String _estadoPedidoLabel(String estado) {
    switch (estado) {
      case 'en_proceso':
        return 'En proceso';
      case 'listo':
        return 'Listo para entregar';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}

class _ProductoConsolidadoBuilder {
  _ProductoConsolidadoBuilder({
    required this.key,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.variante,
    required this.presentacion,
    required this.equivalencia,
    this.marca,
    this.empresa,
    this.categoria,
    this.subcategoria,
    this.unidadBase = 'UND',
    this.pendientePrecio = false,
    this.imagenPath,
  });

  final String key;
  final String productoId;
  final String codigo;
  final String nombre;
  final String? marca;
  final String? empresa;
  final String? categoria;
  final String? subcategoria;
  final String variante;
  final String presentacion;
  final String equivalencia;
  final String unidadBase;
  final String? imagenPath;
  bool pendientePrecio;
  int totalRequerido = 0;
  int totalPreparado = 0;
  final List<DistribucionPedido> distribucion = [];
  final List<PreparacionDisponible> disponibles = [];

  ProductoConsolidado build() => ProductoConsolidado(
    key: key,
    productoId: productoId,
    codigo: codigo,
    nombre: nombre,
    marca: marca,
    empresa: empresa,
    categoria: categoria,
    subcategoria: subcategoria,
    variante: variante,
    presentacion: presentacion,
    equivalencia: equivalencia,
    imagenPath: imagenPath,
    unidadBase: unidadBase,
    pendientePrecio: pendientePrecio,
    totalRequerido: totalRequerido,
    totalPreparado: totalPreparado,
    distribucion: distribucion,
    disponibles: disponibles,
  );
}

class _PedidoPreparacionBuilder {
  _PedidoPreparacionBuilder({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.telefono,
    required this.direccion,
    required this.referencia,
    required this.fecha,
    required this.estadoPedido,
    required this.estadoCarga,
    required this.paquetes,
  });

  final String id;
  final String codigo;
  final String cliente;
  final String telefono;
  final String direccion;
  final String referencia;
  final DateTime fecha;
  final String estadoPedido;
  final String estadoCarga;
  final int paquetes;
  final Set<String> empresas = {};
  final Set<String> categorias = {};
  final List<ProductoPreparacion> productos = [];

  void registrarClasificacion({
    required String empresa,
    required String categoria,
  }) {
    final empresaLimpia = empresa.trim();
    final categoriaLimpia = categoria.trim();
    if (empresaLimpia.isNotEmpty) empresas.add(empresaLimpia);
    if (categoriaLimpia.isNotEmpty) categorias.add(categoriaLimpia);
  }

  PedidoPreparacion build() => PedidoPreparacion(
    id: id,
    codigo: codigo,
    cliente: cliente,
    telefono: telefono,
    direccion: direccion,
    referencia: referencia,
    fecha: fecha,
    estadoPedido: estadoPedido,
    estadoCarga: estadoCarga,
    paquetes: paquetes,
    productos: productos,
    empresa: _resumenValores(empresas, fallback: 'Sin empresa'),
    categoria: _resumenValores(categorias, fallback: 'Sin categoría'),
    zonaAlmacen: _resolverZonaAlmacen(categorias),
    zonaEntrega: _resolverZonaEntrega(direccion, referencia),
  );

  String _resumenValores(Set<String> valores, {required String fallback}) {
    if (valores.isEmpty) return fallback;
    final ordenados = valores.toList()..sort();
    if (ordenados.length == 1) return ordenados.first;
    return '${ordenados.first} +${ordenados.length - 1}';
  }

  String _resolverZonaAlmacen(Set<String> categorias) {
    final texto = categorias.join(' ').toLowerCase();
    if (texto.contains('perner')) return 'Pasillo A • Pernería';
    if (texto.contains('herramientas eléctricas')) {
      return 'Pasillo B • Herramientas eléctricas';
    }
    if (texto.contains('herramientas manuales')) {
      return 'Pasillo C • Herramientas manuales';
    }
    if (texto.contains('purificador')) return 'Pasillo D • Purificadores';
    if (texto.contains('limpieza')) return 'Pasillo E • Limpieza';
    if (categorias.isNotEmpty) return 'Zona ${categorias.first}';
    return 'Sin zona de almacén';
  }

  String _resolverZonaEntrega(String direccion, String referencia) {
    final texto = '$direccion $referencia'.toLowerCase();
    if (texto.contains('norte')) return 'Norte';
    if (texto.contains('sur')) return 'Sur';
    if (texto.contains('este')) return 'Este';
    if (texto.contains('oeste')) return 'Oeste';
    if (texto.contains('centro') || texto.contains('principal')) {
      return 'Centro';
    }
    return 'Zona por asignar';
  }
}
