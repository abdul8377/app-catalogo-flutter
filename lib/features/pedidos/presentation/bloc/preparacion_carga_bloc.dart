import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pedido.dart';
import '../../domain/repositories/pedidos_repository.dart';
import 'preparacion_carga_event.dart';
import 'preparacion_carga_state.dart';

class PreparacionCargaBloc
    extends Bloc<PreparacionCargaEvent, PreparacionCargaState> {
  PreparacionCargaBloc(this._repository)
    : super(PreparacionCargaState.initial()) {
    on<PreparacionCargaStarted>(_started);
    on<PreparacionCargaRecargada>(_recargar);
    on<PreparacionCargaSubTabCambiada>(
      (event, emit) => emit(
        state.copyWith(
          subTab: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<PreparacionCargaModoAgrupacionCambiado>(
      (event, emit) => emit(
        state.copyWith(
          modoAgrupacion: event.modo,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<PreparacionCargaPreparacionRegistrada>(_registrarPreparacion);
    on<PreparacionCargaPedidoCargado>(_marcarCargado);
  }

  final PedidosRepository _repository;

  Future<void> _started(
    PreparacionCargaStarted event,
    Emitter<PreparacionCargaState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));
    await _cargar(emit, loading: false);
  }

  Future<void> _recargar(
    PreparacionCargaRecargada event,
    Emitter<PreparacionCargaState> emit,
  ) async {
    await _cargar(emit);
  }

  Future<void> _registrarPreparacion(
    PreparacionCargaPreparacionRegistrada event,
    Emitter<PreparacionCargaState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearError: true, clearMessage: true));
    try {
      await _repository.registrarPreparacionProducto(event.preparacion);
      final results = await Future.wait([
        _repository.obtenerPedidosPreparacion(),
        _repository.obtenerHojaActiva(),
      ]);
      final pedidos = results[0] as List;
      final hoja = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          saving: false,
          pedidos: pedidos.cast(),
          hojaActivaCodigo: hoja?.codigo,
          clearHojaActiva: hoja == null,
          message: 'Preparación registrada correctamente.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: 'No se pudo registrar la preparación: $error',
        ),
      );
    }
  }

  Future<void> _marcarCargado(
    PreparacionCargaPedidoCargado event,
    Emitter<PreparacionCargaState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearError: true, clearMessage: true));
    try {
      await _repository.marcarPedidoCargado(
        pedidoId: event.pedidoId,
        paquetes: event.paquetes,
        observacion: event.observacion,
      );
      final results = await Future.wait([
        _repository.obtenerPedidosPreparacion(),
        _repository.obtenerHojaActiva(),
      ]);
      final pedidos = results[0] as List;
      final hoja = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          saving: false,
          pedidos: pedidos.cast(),
          hojaActivaCodigo: hoja?.codigo,
          clearHojaActiva: hoja == null,
          message: 'Pedido marcado como cargado.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: 'No se pudo marcar el pedido como cargado: $error',
        ),
      );
    }
  }

  Future<void> _cargar(
    Emitter<PreparacionCargaState> emit, {
    bool loading = false,
  }) async {
    try {
      final results = await Future.wait([
        _repository.obtenerPedidosPreparacion(),
        _repository.obtenerHojaActiva(),
      ]);
      final pedidos = results[0] as List;
      final hoja = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          loading: loading,
          pedidos: pedidos.cast(),
          hojaActivaCodigo: hoja?.codigo,
          clearHojaActiva: hoja == null,
          clearError: true,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar preparación y carga.',
        ),
      );
    }
  }
}
