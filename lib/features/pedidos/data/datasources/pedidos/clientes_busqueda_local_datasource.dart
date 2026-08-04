part of '../pedidos_local_datasource.dart';

extension ClientesBusquedaLocalDatasource on PedidosLocalDatasource {
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
}
