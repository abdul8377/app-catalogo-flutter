import 'package:equatable/equatable.dart';

class DashboardCotizacion extends Equatable {
  const DashboardCotizacion({
    required this.id,
    required this.pedidoId,
    required this.codigo,
    required this.pedidoCodigo,
    required this.cliente,
    required this.total,
    required this.estado,
    required this.fecha,
    required this.tienePdf,
  });

  final String id;
  final String pedidoId;
  final String codigo;
  final String pedidoCodigo;
  final String cliente;
  final double total;
  final String estado;
  final DateTime fecha;
  final bool tienePdf;

  bool get esBorrador => estado.trim().toLowerCase() == 'borrador';

  @override
  List<Object?> get props => [
    id,
    pedidoId,
    codigo,
    pedidoCodigo,
    cliente,
    total,
    estado,
    fecha,
    tienePdf,
  ];
}
