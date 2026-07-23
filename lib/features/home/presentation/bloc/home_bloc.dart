import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pedidos/domain/entities/pedido.dart';
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
    try {
      hoja = await _pedidosRepository.obtenerHojaActiva();
    } catch (_) {
      hoja = null;
    }

    emit(
      HomeState(
        loading: false,
        vendedorNombre: 'Alfonzo Esteban',
        sincronizado: true,
        tieneHojaActiva: hoja != null,
        codigoHojaActiva: hoja?.codigo,
        estadoHojaActiva: hoja?.estado,
        pedidosPendientes: 3,
        pedidosEnProceso: 2,
        pedidosListos: 1,
        pedidosEntregados: 4,
        productosSinPrecio: 2,
        cambiosSinSincronizar: 6,
      ),
    );
  }
}
