import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pedidos/domain/entities/pedido.dart';
import '../../../pedidos/domain/entities/resumen_hoy.dart';
import '../../../pedidos/domain/repositories/pedidos_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._pedidosRepository) : super(HomeState.initial()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeRefreshed>(_onHomeStarted);
  }
  final PedidosRepository _pedidosRepository;

  Future<void> _onHomeStarted(HomeEvent event, Emitter<HomeState> emit) async {
    HojaPedidoActiva? hoja;
    var resumen = const ResumenHoy(
      vendedorNombre: 'Usuario',
      pedidosPendientes: 0,
      pedidosEnProceso: 0,
      pedidosListos: 0,
      pedidosEntregados: 0,
      productosSinPrecio: 0,
      cambiosSinSincronizar: 0,
    );
    try {
      hoja = await _pedidosRepository.obtenerHojaActiva();
    } catch (_) {
      hoja = null;
    }
    try {
      resumen = await _pedidosRepository.obtenerResumenHoy();
    } catch (_) {
      // El Home continúa utilizable con contadores en cero.
    }

    emit(
      HomeState(
        loading: false,
        vendedorNombre: resumen.vendedorNombre,
        sincronizado: resumen.sincronizado,
        tieneHojaActiva: hoja != null,
        codigoHojaActiva: hoja?.codigo,
        estadoHojaActiva: hoja?.estado,
        pedidosPendientes: resumen.pedidosPendientes,
        pedidosEnProceso: resumen.pedidosEnProceso,
        pedidosListos: resumen.pedidosListos,
        pedidosEntregados: resumen.pedidosEntregados,
        productosSinPrecio: resumen.productosSinPrecio,
        cambiosSinSincronizar: resumen.cambiosSinSincronizar,
      ),
    );
  }
}
