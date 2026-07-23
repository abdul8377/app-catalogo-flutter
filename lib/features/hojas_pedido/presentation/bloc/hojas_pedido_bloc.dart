import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/hojas_pedido_repository.dart';
import 'hojas_pedido_event.dart';
import 'hojas_pedido_state.dart';

class HojasPedidoBloc extends Bloc<HojasPedidoEvent, HojasPedidoState> {
  HojasPedidoBloc(this._repository) : super(HojasPedidoState.initial()) {
    on<HojasPedidoStarted>(_iniciar);
    on<HojasPedidoRecargadas>(_recargar);
    on<HojasPedidoTabCambiado>(
      (event, emit) => emit(
        state.copyWith(
          currentTab: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<HojasPedidoBusquedaCambiada>(
      (event, emit) => emit(
        state.copyWith(
          busqueda: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<HojasPedidoFiltroCambiado>(
      (event, emit) => emit(
        state.copyWith(
          filtro: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<HojasPedidoOrdenCambiado>(
      (event, emit) => emit(
        state.copyWith(
          orden: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<HojasPedidoCreada>(_crear);
    on<HojasPedidoCompletada>(_completar);
  }

  final HojasPedidoRepository _repository;

  Future<void> _iniciar(
    HojasPedidoStarted event,
    Emitter<HojasPedidoState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));
    await _cargar(emit, loading: false);
  }

  Future<void> _recargar(
    HojasPedidoRecargadas event,
    Emitter<HojasPedidoState> emit,
  ) async {
    emit(
      state.copyWith(actualizando: true, clearError: true, clearMessage: true),
    );
    await _cargar(emit, actualizando: false);
  }

  Future<void> _crear(
    HojasPedidoCreada event,
    Emitter<HojasPedidoState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearError: true, clearMessage: true));
    try {
      await _repository.crearHoja(
        vendedor: event.vendedor,
        referencia: event.referencia,
        observacion: event.observacion,
      );
      final hojas = await _repository.obtenerHojas();
      emit(
        state.copyWith(
          saving: false,
          currentTab: 0,
          hojas: hojas,
          message: 'Hoja creada correctamente.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: _mensajeError('No se pudo crear la hoja', error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _completar(
    HojasPedidoCompletada event,
    Emitter<HojasPedidoState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearError: true, clearMessage: true));
    try {
      await _repository.completarHoja(
        hojaId: event.hojaId,
        usuario: event.usuario,
        observacion: event.observacion,
      );
      final hojas = await _repository.obtenerHojas();
      emit(
        state.copyWith(
          saving: false,
          currentTab: 1,
          hojas: hojas,
          message: 'Hoja completada correctamente.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: _mensajeError('No se pudo completar la hoja', error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _cargar(
    Emitter<HojasPedidoState> emit, {
    bool? loading,
    bool? actualizando,
  }) async {
    try {
      final hojas = await _repository.obtenerHojas();
      emit(
        state.copyWith(
          loading: loading,
          actualizando: actualizando,
          hojas: hojas,
          clearError: true,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          actualizando: false,
          error: _mensajeError('No se pudieron cargar las hojas', error),
        ),
      );
    }
  }

  String _mensajeError(String prefix, Object error) {
    final detalle = error.toString().replaceFirst('Bad state: ', '');
    return '$prefix: $detalle';
  }
}
