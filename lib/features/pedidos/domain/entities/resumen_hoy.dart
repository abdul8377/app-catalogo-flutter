import 'package:equatable/equatable.dart';

class ResumenHoy extends Equatable {
  const ResumenHoy({
    required this.vendedorNombre,
    required this.pedidosPendientes,
    required this.pedidosEnProceso,
    required this.pedidosListos,
    required this.pedidosEntregados,
    required this.productosSinPrecio,
    required this.cambiosSinSincronizar,
  });

  final String vendedorNombre;
  final int pedidosPendientes;
  final int pedidosEnProceso;
  final int pedidosListos;
  final int pedidosEntregados;
  final int productosSinPrecio;
  final int cambiosSinSincronizar;

  bool get sincronizado => cambiosSinSincronizar == 0;

  @override
  List<Object?> get props => [
    vendedorNombre,
    pedidosPendientes,
    pedidosEnProceso,
    pedidosListos,
    pedidosEntregados,
    productosSinPrecio,
    cambiosSinSincronizar,
  ];
}
