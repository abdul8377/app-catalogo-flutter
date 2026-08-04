part of '../pedidos_local_datasource.dart';

extension _PedidosResumenMapping on PedidosLocalDatasource {
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
}
