import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/hoja_pedido.dart';

class HojasPedidoLocalDatasource {
  const HojasPedidoLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<HojaPedido>> obtenerHojas() async {
    final db = await _db;
    final rows = await db.query(
      'hojas_pedido',
      orderBy: 'activa DESC, creado_en DESC',
    );
    final hojas = <HojaPedido>[];
    for (final row in rows) {
      hojas.add(await _cargarHoja(db, row));
    }
    return hojas;
  }

  Future<HojaPedido?> obtenerHoja(String id) async {
    final db = await _db;
    final rows = await db.query(
      'hojas_pedido',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _cargarHoja(db, rows.first);
  }

  Future<HojaPedido> crearHoja({
    required String vendedor,
    String referencia = '',
    String observacion = '',
  }) async {
    final vendedorLimpio = vendedor.trim();
    if (vendedorLimpio.isEmpty) {
      throw StateError('El vendedor responsable es obligatorio.');
    }
    final db = await _db;
    final id = await db.transaction((txn) async {
      final activas = Sqflite.firstIntValue(
        await txn.rawQuery(
          "SELECT COUNT(*) FROM hojas_pedido WHERE activa = 1 AND estado = 'Abierta'",
        ),
      );
      if ((activas ?? 0) > 0) {
        throw StateError('Ya existe una hoja de pedido abierta.');
      }

      final now = DateTime.now();
      final count = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM hojas_pedido WHERE creado_en LIKE ?',
          ['${now.year}-%'],
        ),
      );
      final codigo =
          'HP-${now.year}-${((count ?? 0) + 1).toString().padLeft(3, '0')}';
      final hojaId = const Uuid().v4();
      final nowIso = now.toIso8601String();
      await txn.insert('hojas_pedido', {
        'id': hojaId,
        'codigo': codigo,
        'estado': 'Abierta',
        'activa': 1,
        'vendedor': vendedorLimpio,
        'referencia': referencia.trim(),
        'observacion': observacion.trim(),
        'sincronizado': 0,
        'creado_en': nowIso,
      });
      await txn.insert('hoja_historial', {
        'id': const Uuid().v4(),
        'hoja_id': hojaId,
        'evento': 'Hoja $codigo creada',
        'responsable': vendedorLimpio,
        'creado_en': nowIso,
      });
      return hojaId;
    });
    return (await obtenerHoja(id))!;
  }

  Future<void> completarHoja({
    required String hojaId,
    required String usuario,
    String observacion = '',
  }) async {
    final usuarioLimpio = usuario.trim();
    if (usuarioLimpio.isEmpty) {
      throw StateError('El usuario que completa la hoja es obligatorio.');
    }
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'hojas_pedido',
        columns: ['id', 'codigo'],
        where: "id = ? AND activa = 1 AND estado = 'Abierta'",
        whereArgs: [hojaId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('La hoja ya no está abierta.');
      }
      final nowIso = DateTime.now().toIso8601String();
      await txn.update(
        'hojas_pedido',
        {
          'estado': 'Completada',
          'activa': 0,
          'fecha_cierre': nowIso,
          'usuario_cierre': usuarioLimpio,
          'observacion': observacion.trim(),
          'sincronizado': 0,
        },
        where: 'id = ?',
        whereArgs: [hojaId],
      );
      await txn.insert('hoja_historial', {
        'id': const Uuid().v4(),
        'hoja_id': hojaId,
        'evento': 'Hoja completada',
        'observacion': observacion.trim(),
        'responsable': usuarioLimpio,
        'creado_en': nowIso,
      });
    });
  }

  Future<HojaPedido> _cargarHoja(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final id = row['id'] as String;
    final pedidosRows = await db.rawQuery(
      '''
      SELECT p.id,
             p.codigo,
             p.cliente_id,
             p.vendedor,
             p.estado,
             p.subtotal_conocido,
             p.total_parcial,
             COALESCE(cv.total, p.subtotal_conocido) AS total_vigente,
             p.creado_en,
             c.nombre AS cliente_nombre,
             COUNT(i.id) AS cantidad_productos,
             CASE
               WHEN cv.id IS NOT NULL THEN 0
               ELSE SUM(CASE WHEN i.precio_unitario IS NULL THEN 1 ELSE 0 END)
             END AS productos_sin_precio,
             COALESCE(SUM(i.cantidad * i.factor_unidad_base), 0) AS cantidad_solicitada,
             CASE
               WHEN LOWER(p.estado) LIKE 'listo%'
                 OR LOWER(p.estado) = 'entregado'
               THEN COALESCE(SUM(i.cantidad * i.factor_unidad_base), 0)
               ELSE COALESCE(SUM(prep.preparada), 0)
             END AS cantidad_preparada,
             MAX(
               CASE
                 WHEN pc.id IS NOT NULL
                   OR LOWER(p.estado) LIKE 'listo%'
                   OR LOWER(p.estado) = 'entregado'
                 THEN 1 ELSE 0
               END
             ) AS cargado
      FROM pedidos p
      INNER JOIN clientes c ON c.id = p.cliente_id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = p.id
           AND LOWER(co.estado) <> 'borrador'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      LEFT JOIN pedido_items i ON i.pedido_id = p.id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      LEFT JOIN pedido_cargas pc ON pc.pedido_id = p.id
      WHERE p.hoja_id = ?
      GROUP BY p.id
      ORDER BY p.creado_en DESC
      ''',
      [id],
    );

    final pedidos = pedidosRows.map((pedido) {
      final solicitada = _int(pedido['cantidad_solicitada']);
      final preparada = _int(pedido['cantidad_preparada']);
      final sinPrecio = _int(pedido['productos_sin_precio']);
      return PedidoEnHoja(
        id: pedido['id'] as String,
        codigo: pedido['codigo'] as String,
        clienteId: pedido['cliente_id'] as String,
        cliente: pedido['cliente_nombre'] as String? ?? '',
        cantidadProductos: _int(pedido['cantidad_productos']),
        total: sinPrecio == 0 ? _double(pedido['total_vigente']) : null,
        productosSinPrecio: sinPrecio,
        estado: pedido['estado'] as String? ?? 'Pendiente',
        progresoPreparacion: solicitada == 0
            ? 0
            : (preparada / solicitada).clamp(0, 1).toDouble(),
        cargado: _int(pedido['cargado']) == 1,
        fecha:
            DateTime.tryParse(pedido['creado_en'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();

    final productosRows = await db.rawQuery(
      '''
      SELECT i.producto_id,
             i.codigo,
             i.nombre,
             i.unidad_base AS presentacion,
             i.equivalencia,
             SUM(i.cantidad * i.factor_unidad_base) AS cantidad_total,
             COALESCE(SUM(prep.preparada), 0) AS cantidad_preparada,
             COUNT(DISTINCT i.pedido_id) AS pedidos_incluidos
      FROM pedido_items i
      INNER JOIN pedidos p ON p.id = i.pedido_id
      LEFT JOIN (
        SELECT pedido_item_id, SUM(cantidad_base) AS preparada
        FROM preparacion_productos
        GROUP BY pedido_item_id
      ) prep ON prep.pedido_item_id = i.id
      WHERE p.hoja_id = ? AND p.estado != 'Cancelado'
      GROUP BY i.producto_id
      ORDER BY cantidad_total DESC, i.nombre ASC
      ''',
      [id],
    );
    final productos = productosRows.map((producto) {
      final productoId = producto['producto_id'] as String? ?? '';
      final presentacion = producto['presentacion'] as String? ?? '';
      final equivalencia = producto['equivalencia'] as String? ?? '';
      return ProductoEnHoja(
        key: '$productoId|$presentacion|$equivalencia',
        productoId: productoId,
        codigo: producto['codigo'] as String? ?? '',
        nombre: producto['nombre'] as String? ?? '',
        presentacion: presentacion,
        equivalencia: equivalencia,
        cantidadTotal: _int(producto['cantidad_total']),
        cantidadPreparada: _int(producto['cantidad_preparada']),
        pedidosQueLoIncluyen: _int(producto['pedidos_incluidos']),
      );
    }).toList();

    final clientesRows = await db.rawQuery(
      '''
      SELECT c.id,
             c.nombre,
             c.telefono,
             c.direccion,
             COUNT(DISTINCT p.id) AS cantidad_pedidos,
             COALESCE(
               SUM(
                 (SELECT COUNT(*)
                    FROM pedido_items pi
                   WHERE pi.pedido_id = p.id)
               ),
               0
             ) AS cantidad_productos,
             COALESCE(SUM(COALESCE(cv.total, p.subtotal_conocido)), 0)
               AS subtotal_conocido
      FROM pedidos p
      INNER JOIN clientes c ON c.id = p.cliente_id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = p.id
           AND LOWER(co.estado) <> 'borrador'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      WHERE p.hoja_id = ?
      GROUP BY c.id
      ORDER BY c.nombre ASC
      ''',
      [id],
    );
    final clientes = clientesRows
        .map(
          (cliente) => ClienteEnHoja(
            id: cliente['id'] as String,
            nombre: cliente['nombre'] as String? ?? '',
            telefono: cliente['telefono'] as String? ?? '',
            direccion: cliente['direccion'] as String? ?? '',
            cantidadPedidos: _int(cliente['cantidad_pedidos']),
            cantidadProductos: _int(cliente['cantidad_productos']),
            subtotalConocido: _double(cliente['subtotal_conocido']),
          ),
        )
        .toList();

    final historialRows = await db.query(
      'hoja_historial',
      where: 'hoja_id = ?',
      whereArgs: [id],
      orderBy: 'creado_en ASC',
    );
    final historial = historialRows
        .map(
          (entrada) => HistorialHojaEntrada(
            fecha:
                DateTime.tryParse(entrada['creado_en'] as String? ?? '') ??
                DateTime.now(),
            evento: _eventoConObservacion(entrada),
            responsable: entrada['responsable'] as String?,
          ),
        )
        .toList();
    if (historial.isEmpty) {
      historial.add(
        HistorialHojaEntrada(
          fecha:
              DateTime.tryParse(row['creado_en'] as String? ?? '') ??
              DateTime.now(),
          evento: 'Hoja ${row['codigo']} creada',
          responsable: _texto(row['vendedor']),
        ),
      );
    }
    for (final pedido in pedidos.reversed) {
      historial.add(
        HistorialHojaEntrada(
          fecha: pedido.fecha,
          evento: 'Pedido ${pedido.codigo} agregado',
        ),
      );
    }
    historial.sort((a, b) => a.fecha.compareTo(b.fecha));

    final totalSolicitado = productos.fold<int>(
      0,
      (sum, producto) => sum + producto.cantidadTotal,
    );
    final totalPreparado = productos.fold<int>(
      0,
      (sum, producto) => sum + producto.cantidadPreparada,
    );
    final totalCargados = pedidos.where((pedido) => pedido.cargado).length;
    final vendedor = _texto(row['vendedor']);

    return HojaPedido(
      id: id,
      codigo: row['codigo'] as String,
      estado: row['estado'] as String? ?? 'Completada',
      vendedor: vendedor.isEmpty
          ? _vendedorDesdePedidos(pedidosRows)
          : vendedor,
      fechaApertura:
          DateTime.tryParse(row['creado_en'] as String? ?? '') ??
          DateTime.now(),
      fechaCierre: DateTime.tryParse(_texto(row['fecha_cierre'])),
      referencia: _texto(row['referencia']),
      observacion: _texto(row['observacion']),
      sincronizado: _int(row['sincronizado']) == 1,
      usuarioCierre: row['usuario_cierre'] as String?,
      totalPedidos: pedidos.length,
      totalClientes: clientes.length,
      totalProductosDiferentes: productos.length,
      totalUnidades: totalSolicitado,
      subtotalConocido: pedidosRows.fold<double>(
        0,
        (sum, pedido) => sum + _double(pedido['total_vigente']),
      ),
      pedidosPendientesPrecio: pedidos
          .where((pedido) => !pedido.tienePrecio)
          .length,
      pedidosPendientes: _contarEstado(pedidos, 'pendiente'),
      pedidosEnProceso: _contarEstado(pedidos, 'proceso'),
      pedidosListos: _contarEstado(pedidos, 'listo'),
      pedidosEntregados: _contarEstado(pedidos, 'entregado'),
      pedidosCancelados: _contarEstado(pedidos, 'cancelado'),
      progresoPreparacion: totalSolicitado == 0
          ? 0
          : (totalPreparado / totalSolicitado).clamp(0, 1).toDouble(),
      progresoCarga: pedidos.isEmpty ? 0 : totalCargados / pedidos.length,
      pedidos: pedidos,
      productos: productos,
      clientes: clientes,
      historial: historial,
    );
  }

  int _contarEstado(List<PedidoEnHoja> pedidos, String estado) => pedidos
      .where((pedido) => pedido.estado.toLowerCase().contains(estado))
      .length;

  String _vendedorDesdePedidos(List<Map<String, Object?>> pedidos) => pedidos
      .map((pedido) => _texto(pedido['vendedor']))
      .firstWhere((value) => value.isNotEmpty, orElse: () => 'Alfonzo Esteban');

  String _eventoConObservacion(Map<String, Object?> row) {
    final evento = _texto(row['evento']);
    final observacion = _texto(row['observacion']);
    return observacion.isEmpty ? evento : '$evento\n$observacion';
  }

  String _texto(Object? value) => value?.toString().trim() ?? '';

  int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
}
