import 'package:equatable/equatable.dart';

class DashboardActividad extends Equatable {
  const DashboardActividad({
    required this.evento,
    required this.fecha,
    required this.tipo,
    this.detalle = '',
  });

  final String evento;
  final DateTime fecha;
  final String tipo;
  final String detalle;

  @override
  List<Object?> get props => [evento, fecha, tipo, detalle];
}
