part of '../pedidos_local_datasource.dart';

extension PreparacionLocalDatasource on PedidosLocalDatasource {
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
            AND i.activo = 1
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
}
