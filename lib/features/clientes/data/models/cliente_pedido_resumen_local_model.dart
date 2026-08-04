class ClientePedidoResumenLocalModel {
  const ClientePedidoResumenLocalModel({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.estado,
    required this.cantidadProductos,
    required this.total,
    required this.totalParcial,
  });

  factory ClientePedidoResumenLocalModel.fromRow(Map<String, Object?> row) =>
      ClientePedidoResumenLocalModel(
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

  final String id;
  final String codigo;
  final DateTime fecha;
  final String estado;
  final int cantidadProductos;
  final double total;
  final bool totalParcial;
}
