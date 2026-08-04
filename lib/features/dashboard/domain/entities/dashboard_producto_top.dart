import 'package:equatable/equatable.dart';

class DashboardProductoTop extends Equatable {
  const DashboardProductoTop({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.marca,
    required this.unidadBase,
    required this.cantidadRequerida,
    required this.cantidadPreparada,
    required this.pedidos,
    this.presentacion = 'Presentación',
  });

  final String productoId;
  final String nombre;
  final String codigo;
  final String marca;
  final String unidadBase;
  final String presentacion;
  final int cantidadRequerida;
  final int cantidadPreparada;
  final int pedidos;

  int get cantidadPendiente => (cantidadRequerida - cantidadPreparada)
      .clamp(0, cantidadRequerida)
      .toInt();

  double get progreso => cantidadRequerida <= 0
      ? 0
      : (cantidadPreparada / cantidadRequerida).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
    productoId,
    nombre,
    codigo,
    marca,
    unidadBase,
    presentacion,
    cantidadRequerida,
    cantidadPreparada,
    pedidos,
  ];
}
