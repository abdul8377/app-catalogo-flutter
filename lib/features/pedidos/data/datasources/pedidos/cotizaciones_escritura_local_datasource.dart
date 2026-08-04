part of '../pedidos_local_datasource.dart';

extension CotizacionesEscrituraLocalDatasource on PedidosLocalDatasource {
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
                'SELECT COUNT(*) FROM pedido_items WHERE pedido_id = ? AND activo = 1',
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
}
