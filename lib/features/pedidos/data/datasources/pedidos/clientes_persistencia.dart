part of '../pedidos_local_datasource.dart';

extension _ClientesPersistencia on PedidosLocalDatasource {
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
    final now = DateTime.now().toIso8601String();
    await txn.insert('clientes', {
      'id': id,
      'nombre': cliente.nombre,
      'tipo': cliente.ruc.trim().isEmpty ? 'Persona' : 'Empresa',
      'telefono': cliente.telefono,
      'dni': cliente.dni,
      'ruc': cliente.ruc,
      'tipo_entrega': 'entrega',
      'direccion': cliente.direccion,
      'referencia': cliente.referencia,
      'foto_ubicacion_path': cliente.fotoUbicacionPath,
      'activo': 1,
      'observaciones': cliente.observaciones,
      'creado_en': now,
      'actualizado_en': now,
    });
    return id;
  }

  ClientePedido _clienteFromMap(Map<String, Object?> row) => ClientePedido(
    id: row['id'] as String,
    nombre: row['nombre'] as String,
    telefono: row['telefono'] as String,
    dni: row['dni'] as String,
    ruc: row['ruc'] as String,
    tipoEntrega: 'entrega',
    direccion: row['direccion'] as String,
    referencia: row['referencia'] as String,
    fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
    observaciones: row['observaciones'] as String,
  );
}
