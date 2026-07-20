import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_pedido_resumen.dart';
import '../../domain/entities/nuevo_cliente.dart';

class ClientesLocalDatasource {
  const ClientesLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<Cliente>> obtenerClientes() async {
    final rows = await (await _db).rawQuery('''
      SELECT c.*,
             COUNT(p.id) AS pedidos_count,
             MAX(p.creado_en) AS ultimo_pedido
      FROM clientes c
      LEFT JOIN pedidos p ON p.cliente_id = c.id
      GROUP BY c.id
      ORDER BY c.nombre COLLATE NOCASE
    ''');
    return rows.map(_clienteFromMap).toList();
  }

  Future<Cliente?> obtenerCliente(String id) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT c.*,
             COUNT(p.id) AS pedidos_count,
             MAX(p.creado_en) AS ultimo_pedido
      FROM clientes c
      LEFT JOIN pedidos p ON p.cliente_id = c.id
      WHERE c.id = ?
      GROUP BY c.id
      LIMIT 1
    ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return _clienteFromMap(rows.first);
  }

  Future<List<ClientePedidoResumen>> obtenerPedidosCliente(
    String clienteId,
  ) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT p.id,
             p.codigo,
             p.creado_en,
             p.estado,
             p.subtotal_conocido,
             p.total_parcial,
             COUNT(i.id) AS cantidad_productos
      FROM pedidos p
      LEFT JOIN pedido_items i ON i.pedido_id = p.id
      WHERE p.cliente_id = ?
      GROUP BY p.id
      ORDER BY p.creado_en DESC
      LIMIT 30
    ''',
      [clienteId],
    );
    return rows.map(_pedidoFromMap).toList();
  }

  Future<void> guardarCliente(NuevoCliente cliente) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert('clientes', {
      'id': const Uuid().v4(),
      ..._clienteToMap(cliente),
      'creado_en': now,
      'actualizado_en': now,
    });
  }

  Future<void> actualizarCliente(String id, NuevoCliente cliente) async {
    await (await _db).update(
      'clientes',
      {
        ..._clienteToMap(cliente),
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cambiarEstadoCliente(String id, {required bool activo}) async {
    await (await _db).update(
      'clientes',
      {
        'activo': activo ? 1 : 0,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _clienteToMap(NuevoCliente cliente) => {
    'nombre': cliente.nombre,
    'tipo': cliente.tipo,
    'telefono': cliente.telefono,
    'dni': cliente.dni,
    'ruc': cliente.ruc,
    'tipo_entrega': 'entrega',
    'direccion': cliente.direccion,
    'referencia': cliente.referencia,
    'foto_ubicacion_path': cliente.fotoUbicacionPath,
    'activo': cliente.activo ? 1 : 0,
    'observaciones': cliente.observaciones,
  };

  Cliente _clienteFromMap(Map<String, Object?> row) {
    final creado = DateTime.tryParse(row['creado_en'] as String? ?? '');
    final actualizado = DateTime.tryParse(
      row['actualizado_en'] as String? ?? '',
    );
    final ultimoPedido = DateTime.tryParse(
      row['ultimo_pedido'] as String? ?? '',
    );
    final ruc = row['ruc'] as String? ?? '';
    return Cliente(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      tipo: row['tipo'] as String? ?? (ruc.isEmpty ? 'Persona' : 'Empresa'),
      telefono: row['telefono'] as String,
      dni: row['dni'] as String? ?? '',
      ruc: ruc,
      direccion: row['direccion'] as String? ?? '',
      referencia: row['referencia'] as String? ?? '',
      fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
      activo: (row['activo'] as int? ?? 1) == 1,
      pedidosCount: row['pedidos_count'] as int? ?? 0,
      ultimoPedido: ultimoPedido,
      observaciones: row['observaciones'] as String? ?? '',
      fechaRegistro: creado ?? DateTime.now(),
      ultimaActualizacion: actualizado,
    );
  }

  ClientePedidoResumen _pedidoFromMap(Map<String, Object?> row) =>
      ClientePedidoResumen(
        id: row['id'] as String,
        codigo: row['codigo'] as String,
        fecha:
            DateTime.tryParse(row['creado_en'] as String? ?? '') ??
            DateTime.now(),
        estado: row['estado'] as String,
        cantidadProductos: row['cantidad_productos'] as int? ?? 0,
        total: (row['subtotal_conocido'] as num? ?? 0).toDouble(),
        totalParcial: (row['total_parcial'] as int? ?? 0) == 1,
      );
}
