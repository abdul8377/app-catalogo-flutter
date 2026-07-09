import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final bool loading;
  final String vendedorNombre;
  final bool sincronizado;

  final bool tieneHojaActiva;
  final String? codigoHojaActiva;
  final String? estadoHojaActiva;

  final int pedidosPendientes;
  final int pedidosEnProceso;
  final int pedidosListos;
  final int pedidosEntregados;
  final int productosSinPrecio;
  final int cambiosSinSincronizar;

  const HomeState({
    required this.loading,
    required this.vendedorNombre,
    required this.sincronizado,
    required this.tieneHojaActiva,
    this.codigoHojaActiva,
    this.estadoHojaActiva,
    required this.pedidosPendientes,
    required this.pedidosEnProceso,
    required this.pedidosListos,
    required this.pedidosEntregados,
    required this.productosSinPrecio,
    required this.cambiosSinSincronizar,
  });

  factory HomeState.initial() {
    return const HomeState(
      loading: true,
      vendedorNombre: '',
      sincronizado: false,
      tieneHojaActiva: false,
      pedidosPendientes: 0,
      pedidosEnProceso: 0,
      pedidosListos: 0,
      pedidosEntregados: 0,
      productosSinPrecio: 0,
      cambiosSinSincronizar: 0,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    vendedorNombre,
    sincronizado,
    tieneHojaActiva,
    codigoHojaActiva,
    estadoHojaActiva,
    pedidosPendientes,
    pedidosEnProceso,
    pedidosListos,
    pedidosEntregados,
    productosSinPrecio,
    cambiosSinSincronizar,
  ];
}