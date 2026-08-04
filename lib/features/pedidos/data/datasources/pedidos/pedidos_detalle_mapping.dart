part of '../pedidos_local_datasource.dart';

extension _PedidosDetalleMapping on PedidosLocalDatasource {
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
    varianteId: row['variante_id'] as String? ?? '',
    varianteSku: row['variante_sku'] as String? ?? '',
    varianteNombre: row['variante_nombre'] as String? ?? '',
    atributosVariante: _stringMapFromJson(
      row['atributos_variante_json'] as String?,
    ),
    presentacionId: row['presentacion_id'] as String? ?? '',
    precioListaId: row['precio_lista_id'] as String? ?? '',
    precioListaNombre: row['precio_lista_nombre'] as String? ?? '',
    precioConfiguracion:
        row['precio_configuracion'] as String? ?? 'precio_fijo',
    precioPedido: (row['precio_pedido'] as num?)?.toDouble(),
    descuentoCotizado: (row['descuento_cotizado'] as num? ?? 0).toDouble(),
    tipoDescuentoCotizado: row['tipo_descuento_cotizado'] as String? ?? 'monto',
  );
}
