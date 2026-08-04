part of '../pedidos_local_datasource.dart';

extension _PreparacionQueries on PedidosLocalDatasource {
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
        WHERE i.activo = 1
          AND LOWER(p.estado) <> 'cancelado'
          ${soloHojaActiva ? "AND h.activa = 1 AND h.estado = 'Abierta'" : ''}
        GROUP BY i.id
        ORDER BY p.creado_en ASC, i.nombre ASC
      ''');
}
