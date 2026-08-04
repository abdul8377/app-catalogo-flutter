import 'package:equatable/equatable.dart';

class DashboardPedidoReciente extends Equatable {
  const DashboardPedidoReciente({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.productos,
    required this.total,
    required this.productosSinPrecio,
    required this.estado,
    required this.fecha,
    required this.sincronizado,
  });

  final String id;
  final String codigo;
  final String cliente;
  final int productos;
  final double total;
  final int productosSinPrecio;
  final String estado;
  final DateTime fecha;
  final bool sincronizado;

  bool get tienePrecioCompleto => productosSinPrecio == 0;

  @override
  List<Object?> get props => [
    id,
    codigo,
    cliente,
    productos,
    total,
    productosSinPrecio,
    estado,
    fecha,
    sincronizado,
  ];
}
