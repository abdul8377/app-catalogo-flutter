import 'package:equatable/equatable.dart';

class DashboardSyncPendiente extends Equatable {
  const DashboardSyncPendiente({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.estado,
    required this.fecha,
    this.error = '',
  });

  final String id;
  final String tipo;
  final String titulo;
  final String detalle;
  final String estado;
  final DateTime fecha;
  final String error;

  @override
  List<Object?> get props => [id, tipo, titulo, detalle, estado, fecha, error];
}
