import 'package:equatable/equatable.dart';

class DashboardHojaActiva extends Equatable {
  const DashboardHojaActiva({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.vendedor,
    required this.fecha,
    required this.pedidos,
    required this.clientes,
    required this.productos,
    required this.subtotal,
    required this.pendientesPrecio,
  });

  final String id;
  final String codigo;
  final String estado;
  final String vendedor;
  final DateTime fecha;
  final int pedidos;
  final int clientes;
  final int productos;
  final double subtotal;
  final int pendientesPrecio;

  @override
  List<Object?> get props => [
    id,
    codigo,
    estado,
    vendedor,
    fecha,
    pedidos,
    clientes,
    productos,
    subtotal,
    pendientesPrecio,
  ];
}
