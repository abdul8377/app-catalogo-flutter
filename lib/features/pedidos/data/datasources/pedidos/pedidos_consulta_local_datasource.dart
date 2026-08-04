part of '../pedidos_local_datasource.dart';

extension PedidosConsultaLocalDatasource on PedidosLocalDatasource {
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
      LEFT JOIN pedido_items i ON i.pedido_id = p.id AND i.activo = 1
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
                    AND px.activo = 1
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
                    AND px.activo = 1
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
             i.variante_id,
             i.variante_sku,
             i.variante_nombre,
             i.atributos_variante_json,
             i.presentacion_id,
             i.precio_lista_id,
             i.precio_lista_nombre,
             i.precio_configuracion,
             i.precio_unitario AS precio_pedido,
             COALESCE(ci.precio_cotizacion, i.precio_unitario) AS precio_unitario,
             COALESCE(ci.subtotal, i.subtotal) AS subtotal,
             COALESCE(ci.descuento, 0) AS descuento_cotizado,
             COALESCE(ci.tipo_descuento, 'monto') AS tipo_descuento_cotizado,
             pr.marca,
             COALESCE(i.imagen_path, pr.imagen_path) AS imagen_path
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
        AND i.activo = 1
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
}
