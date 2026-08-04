part of '../pedidos_local_datasource.dart';

extension _CotizacionesMapping on PedidosLocalDatasource {
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
}
