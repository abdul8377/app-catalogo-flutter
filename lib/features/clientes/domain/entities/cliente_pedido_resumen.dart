import 'package:equatable/equatable.dart';

class ClientePedidoResumen extends Equatable {
  const ClientePedidoResumen({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.estado,
    required this.cantidadProductos,
    required this.total,
    required this.totalParcial,
  });

  final String id;
  final String codigo;
  final DateTime fecha;
  final String estado;
  final int cantidadProductos;
  final double total;
  final bool totalParcial;

  @override
  List<Object?> get props => [
    id,
    codigo,
    fecha,
    estado,
    cantidadProductos,
    total,
    totalParcial,
  ];
}
