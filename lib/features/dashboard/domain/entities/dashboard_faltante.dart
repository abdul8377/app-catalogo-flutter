import 'package:equatable/equatable.dart';

class DashboardFaltante extends Equatable {
  const DashboardFaltante({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.unidadBase,
    required this.cantidadPendiente,
    required this.pedidosAfectados,
    this.presentacion = 'Presentación',
  });

  final String productoId;
  final String nombre;
  final String codigo;
  final String unidadBase;
  final String presentacion;
  final int cantidadPendiente;
  final int pedidosAfectados;

  @override
  List<Object?> get props => [
    productoId,
    nombre,
    codigo,
    unidadBase,
    presentacion,
    cantidadPendiente,
    pedidosAfectados,
  ];
}
