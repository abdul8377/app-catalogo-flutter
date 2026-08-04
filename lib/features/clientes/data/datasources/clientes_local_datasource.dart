import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_pedido_resumen.dart';
import '../../domain/entities/nuevo_cliente.dart';
import '../mappers/cliente_mapper.dart';
import '../mappers/cliente_pedido_resumen_mapper.dart';
import '../models/cliente_local_model.dart';
import '../models/cliente_pedido_resumen_local_model.dart';

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
    return rows
        .map(ClienteLocalModel.fromRow)
        .map(ClienteMapper.toEntity)
        .toList();
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
    return ClienteMapper.toEntity(ClienteLocalModel.fromRow(rows.first));
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
             COALESCE(cv.total, p.subtotal_conocido) AS subtotal_conocido,
             CASE WHEN cv.id IS NULL THEN p.total_parcial ELSE 0 END
               AS total_parcial,
             COUNT(i.id) AS cantidad_productos
      FROM pedidos p
      LEFT JOIN pedido_items i ON i.pedido_id = p.id
      LEFT JOIN cotizaciones cv ON cv.id = (
        SELECT co.id
          FROM cotizaciones co
         WHERE co.pedido_id = p.id
           AND LOWER(co.estado) <> 'borrador'
         ORDER BY co.version DESC, co.creado_en DESC
         LIMIT 1
      )
      WHERE p.cliente_id = ?
      GROUP BY p.id
      ORDER BY p.creado_en DESC
      LIMIT 30
    ''',
      [clienteId],
    );
    return rows
        .map(ClientePedidoResumenLocalModel.fromRow)
        .map(ClientePedidoResumenMapper.toEntity)
        .toList();
  }

  Future<void> guardarCliente(NuevoCliente cliente) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert('clientes', {
      'id': const Uuid().v4(),
      ...ClienteMapper.nuevoClienteToMap(cliente),
      'creado_en': now,
      'actualizado_en': now,
    });
  }

  Future<void> actualizarCliente(String id, NuevoCliente cliente) async {
    await (await _db).update(
      'clientes',
      {
        ...ClienteMapper.nuevoClienteToMap(cliente),
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
}
