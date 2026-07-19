import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/pedido.dart';

class PedidosLocalDatasource {
  const PedidosLocalDatasource(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<HojaPedidoActiva?> obtenerHojaActiva() async {
    final rows = await (await _db).query(
      'hojas_pedido',
      where: "activa = 1 AND estado = 'Abierta'",
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HojaPedidoActiva(
      id: rows.first['id'] as String,
      codigo: rows.first['codigo'] as String,
      estado: rows.first['estado'] as String,
    );
  }

  Future<HojaPedidoActiva> crearHojaActiva() async {
    final db = await _db;
    return db.transaction((txn) async {
      final now = DateTime.now();
      final count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM hojas_pedido WHERE codigo LIKE ?',
              ['HP-${now.year}-%'],
            ),
          ) ??
          0;
      final codigo = 'HP-${now.year}-${(count + 1).toString().padLeft(3, '0')}';
      final id = const Uuid().v4();
      await txn.update('hojas_pedido', {'activa': 0});
      await txn.insert('hojas_pedido', {
        'id': id,
        'codigo': codigo,
        'estado': 'Abierta',
        'activa': 1,
        'creado_en': now.toIso8601String(),
      });
      return HojaPedidoActiva(id: id, codigo: codigo, estado: 'Abierta');
    });
  }

  Future<List<ClientePedido>> buscarClientes(String query) async {
    final text = query.trim();
    final rows = await (await _db).query(
      'clientes',
      where: text.isEmpty
          ? null
          : 'nombre LIKE ? OR telefono LIKE ? OR dni LIKE ? OR ruc LIKE ?',
      whereArgs: text.isEmpty
          ? null
          : List.filled(4, '%$text%', growable: false),
      orderBy: 'nombre',
      limit: 30,
    );
    return rows.map(_clienteFromMap).toList();
  }

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
        'creado_en': now.toIso8601String(),
      });
      for (final item in items) {
        await txn.insert('pedido_items', {
          'id': const Uuid().v4(),
          'pedido_id': pedidoId,
          'producto_id': item.productoId,
          'codigo': item.codigo,
          'nombre': item.nombre,
          'presentacion': item.presentacion,
          'equivalencia': item.equivalencia,
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
          'subtotal': item.subtotal,
        });
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

  Future<String> _obtenerOCrearCliente(
    Transaction txn,
    ClientePedido cliente,
  ) async {
    if (cliente.id != null) return cliente.id!;
    final matches = await txn.query(
      'clientes',
      columns: ['id'],
      where: 'telefono = ? OR (dni != ? AND dni = ?) OR (ruc != ? AND ruc = ?)',
      whereArgs: [cliente.telefono, '', cliente.dni, '', cliente.ruc],
      limit: 1,
    );
    if (matches.isNotEmpty) return matches.first['id'] as String;
    final id = const Uuid().v4();
    await txn.insert('clientes', {
      'id': id,
      'nombre': cliente.nombre,
      'telefono': cliente.telefono,
      'dni': cliente.dni,
      'ruc': cliente.ruc,
      'tipo_entrega': cliente.tipoEntrega,
      'direccion': cliente.direccion,
      'referencia': cliente.referencia,
      'observaciones': cliente.observaciones,
      'creado_en': DateTime.now().toIso8601String(),
    });
    return id;
  }

  ClientePedido _clienteFromMap(Map<String, Object?> row) => ClientePedido(
    id: row['id'] as String,
    nombre: row['nombre'] as String,
    telefono: row['telefono'] as String,
    dni: row['dni'] as String,
    ruc: row['ruc'] as String,
    tipoEntrega: row['tipo_entrega'] as String,
    direccion: row['direccion'] as String,
    referencia: row['referencia'] as String,
    observaciones: row['observaciones'] as String,
  );
}
