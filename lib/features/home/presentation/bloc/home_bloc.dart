import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState.initial()) {
    on<HomeStarted>(_onHomeStarted);
  }

  Future<void> _onHomeStarted(
      HomeStarted event,
      Emitter<HomeState> emit,
      ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    emit(
      const HomeState(
        loading: false,
        vendedorNombre: 'Alfonzo Esteban',
        sincronizado: true,
        tieneHojaActiva: true,
        codigoHojaActiva: 'HP-0001',
        estadoHojaActiva: 'Abierta',
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