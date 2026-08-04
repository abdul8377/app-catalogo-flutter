import 'package:equatable/equatable.dart';

class DashboardCliente extends Equatable {
  const DashboardCliente({
    required this.id,
    required this.nombre,
    required this.pedidos,
    required this.subtotalConocido,
    required this.ultimoPedido,
    required this.direccion,
  });

  final String id;
  final String nombre;
  final int pedidos;
  final double subtotalConocido;
  final DateTime ultimoPedido;
  final String direccion;

  @override
  List<Object?> get props => [
    id,
    nombre,
    pedidos,
    subtotalConocido,
    ultimoPedido,
    direccion,
  ];
}
