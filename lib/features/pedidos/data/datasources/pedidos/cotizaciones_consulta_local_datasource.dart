part of '../pedidos_local_datasource.dart';

extension CotizacionesConsultaLocalDatasource on PedidosLocalDatasource {
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
}
