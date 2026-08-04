part of '../pedidos_local_datasource.dart';

extension ConsolidadoLocalDatasource on PedidosLocalDatasource {
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
}
