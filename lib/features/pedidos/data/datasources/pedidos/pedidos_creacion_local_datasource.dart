part of '../pedidos_local_datasource.dart';

extension PedidosCreacionLocalDatasource on PedidosLocalDatasource {
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
        await txn.insert(
          'pedido_items',
          _pedidoItemValues(
            item,
            pedidoId: pedidoId,
            itemId: const Uuid().v4(),
          ),
        );
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

  Map<String, Object?> _pedidoItemValues(
    PedidoItem item, {
    required String pedidoId,
    required String itemId,
  }) {
    final selected = item.opcionSeleccionada;
    final factor = selected == null
        ? _factorUnidadBase(item.presentacion, item.equivalencia)
        : selected.equivalenteA.round().clamp(1, 1000000000);
    final unidad = selected?.unidadBase.trim().isNotEmpty == true
        ? selected!.unidadBase
        : _unidadBase(item.presentacion, item.equivalencia);
    return {
      'id': itemId,
      'pedido_id': pedidoId,
      'producto_id': item.productoId,
      'codigo': item.codigo,
      'nombre': item.nombre,
      'presentacion': item.presentacion,
      'equivalencia': item.equivalencia,
      'cantidad': item.cantidad,
      'factor_unidad_base': factor,
      'unidad_base': unidad,
      'precio_unitario': item.precioUnitario,
      'subtotal': item.subtotal,
      'activo': 1,
      'variante_id': item.varianteId,
      'variante_sku': item.varianteSku,
      'variante_nombre': item.varianteNombre,
      'atributos_variante_json': jsonEncode(item.atributosVariante),
      'presentacion_id': item.presentacionId,
      'precio_lista_id': item.precioListaId,
      'precio_lista_nombre': item.precioListaNombre,
      'precio_configuracion': item.precioConfiguracion,
      'imagen_path': item.imagenPath,
    };
  }
}
