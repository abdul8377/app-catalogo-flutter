import 'package:equatable/equatable.dart';

class DashboardPedidoListo extends Equatable {
  const DashboardPedidoListo({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.productos,
    required this.direccion,
  });

  final String id;
  final String codigo;
  final String cliente;
  final int productos;
  final String direccion;

  @override
  List<Object?> get props => [id, codigo, cliente, productos, direccion];
}
