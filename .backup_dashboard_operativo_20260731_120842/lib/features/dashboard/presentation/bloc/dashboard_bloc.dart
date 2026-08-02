import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(DashboardState.initial()) {
    on<DashboardStarted>(_iniciar);
    on<DashboardRefreshed>(_actualizar);
    on<DashboardPeriodoCambiado>(_cambiarPeriodo);
    on<DashboardPedidoCargado>(_cargarPedido);
  }

  final DashboardRepository _repository;

  Future<void> _iniciar(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));
    await _cargar(emit, loading: false);
  }

  Future<void> _actualizar(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(actualizando: true, clearError: true, clearMessage: true),
    );
    await _cargar(emit, actualizando: false);
  }

  Future<void> _cambiarPeriodo(
    DashboardPeriodoCambiado event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        filtro: event.filtro,
        clearError: true,
        clearMessage: true,
      ),
    );
    await _cargar(emit, actualizando: false);
  }

  Future<void> _cargarPedido(
    DashboardPedidoCargado event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(procesando: true, clearError: true, clearMessage: true),
    );
    try {
      await _repository.marcarPedidoCargado(
        pedidoId: event.pedidoId,
        paquetes: event.paquetes,
        observacion: event.observacion,
      );
      final data = await _repository.obtenerDashboard(state.filtro);
      emit(
        state.copyWith(
          procesando: false,
          data: data,
          ultimaActualizacion: DateTime.now(),
          message: 'Carga registrada. El pedido está listo para entregar.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          procesando: false,
          error: _mensaje('No se pudo registrar la carga', error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _cargar(
    Emitter<DashboardState> emit, {
    bool? loading,
    bool? actualizando,
  }) async {
    try {
      final data = await _repository.obtenerDashboard(state.filtro);
      emit(
        state.copyWith(
          loading: loading,
          actualizando: actualizando,
          data: data,
          ultimaActualizacion: DateTime.now(),
          clearError: true,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          actualizando: false,
          error: _mensaje('No se pudo cargar el Dashboard', error),
        ),
      );
    }
  }

  String _mensaje(String prefix, Object error) {
    final detalle = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
    return '$prefix: $detalle';
  }
}
