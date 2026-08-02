import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pedido.dart';
import '../../domain/entities/pedido_resumen.dart';
import '../../domain/repositories/pedidos_repository.dart';
import 'pedidos_listado_event.dart';
import 'pedidos_listado_state.dart';

class PedidosListadoBloc
    extends Bloc<PedidosListadoEvent, PedidosListadoState> {
  PedidosListadoBloc(this._repository) : super(PedidosListadoState.initial()) {
    on<PedidosListadoStarted>(_started);
    on<PedidosListadoRecargado>(_recargar);
    on<PedidosListadoBusquedaCambiada>(
      (event, emit) => emit(
        state.copyWith(
          busqueda: event.value,
          limpiarError: true,
          limpiarMessage: true,
        ),
      ),
    );
    on<PedidosListadoFiltroRapidoCambiado>(_cambiarFiltroRapido);
    on<PedidosListadoFiltrosAvanzadosAplicados>((event, emit) {
      final base = state.copyWith(
        limpiarAvanzados: true,
        limpiarError: true,
        limpiarMessage: true,
      );
      emit(
        base.copyWith(
          estado: event.estado,
          hoja: event.hoja ?? state.hojaActivaCodigo,
          precio: event.precio,
          sincronizacion: event.sincronizacion,
          fechaInicio: event.fechaInicio,
          fechaFin: event.fechaFin,
          cliente: event.cliente,
          vendedor: event.vendedor,
          empresa: event.empresa,
          categoria: event.categoria,
          producto: event.producto,
          cotizacion: event.cotizacion,
          limpiarError: true,
          limpiarMessage: true,
        ),
      );
    });
    on<PedidosListadoFiltrosLimpiados>((_, emit) {
      final base = state.copyWith(
        busqueda: '',
        filtrosRapidos: const {'Todos'},
        orden: 'Más recientes',
        limpiarAvanzados: true,
        limpiarError: true,
        limpiarMessage: true,
      );
      emit(base.copyWith(hoja: state.hojaActivaCodigo));
    });
    on<PedidosListadoOrdenCambiado>(
      (event, emit) => emit(
        state.copyWith(
          orden: event.value,
          limpiarError: true,
          limpiarMessage: true,
        ),
      ),
    );
    on<PedidosListadoEstadoActualizado>(_actualizarEstado);
    on<PedidosListadoPedidoCancelado>(_cancelarPedido);
    on<PedidosListadoPedidoReactivado>(_reactivarPedido);
    on<PedidosListadoSincronizacionReintentada>(_reintentarSincronizacion);
  }

  Future<void> _reintentarSincronizacion(
    PedidosListadoSincronizacionReintentada event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      await _repository.reintentarSincronizacionPedido(event.pedidoId);
      final pedidos = await _repository.obtenerPedidosResumen();
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          message: 'Pedido sincronizado correctamente.',
          limpiarError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo sincronizar el pedido: $error',
          limpiarMessage: true,
        ),
      );
    }
  }

  final PedidosRepository _repository;

  Future<void> _started(
    PedidosListadoStarted event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(loading: true, limpiarError: true, limpiarMessage: true),
    );
    try {
      final results = await Future.wait([
        _repository.obtenerPedidosResumen(),
        _repository.obtenerHojaActiva(),
      ]);
      final pedidos = results[0] as List<PedidoResumen>;
      final hojaActiva = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          loading: false,
          pedidos: pedidos,
          hoja: state.hoja ?? hojaActiva?.codigo,
          hojaActivaCodigo: hojaActiva?.codigo,
          limpiarError: true,
          limpiarMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar el listado de pedidos.',
          limpiarMessage: true,
        ),
      );
    }
  }

  Future<void> _recargar(
    PedidosListadoRecargado event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      final seguiaHojaActiva =
          state.hoja == null || state.hoja == state.hojaActivaCodigo;
      final results = await Future.wait([
        _repository.obtenerPedidosResumen(),
        _repository.obtenerHojaActiva(),
      ]);
      final pedidos = results[0] as List<PedidoResumen>;
      final hojaActiva = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          hoja: seguiaHojaActiva ? hojaActiva?.codigo : state.hoja,
          hojaActivaCodigo: hojaActiva?.codigo,
          limpiarError: true,
          limpiarMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo actualizar el listado de pedidos.',
          limpiarMessage: true,
        ),
      );
    }
  }

  Future<void> _actualizarEstado(
    PedidosListadoEstadoActualizado event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      await _repository.cambiarEstadoPedido(
        pedidoId: event.pedidoId,
        nuevoEstado: event.nuevoEstado,
        observacion: event.observacion,
      );
      final pedidos = await _repository.obtenerPedidosResumen();
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          message: 'Estado del pedido actualizado correctamente.',
          limpiarError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo actualizar el estado: $error',
          limpiarMessage: true,
        ),
      );
    }
  }

  Future<void> _cancelarPedido(
    PedidosListadoPedidoCancelado event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      await _repository.cancelarPedido(
        pedidoId: event.pedidoId,
        motivo: event.motivo,
      );
      final pedidos = await _repository.obtenerPedidosResumen();
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          message: 'Pedido cancelado correctamente.',
          limpiarError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo cancelar el pedido: $error',
          limpiarMessage: true,
        ),
      );
    }
  }

  Future<void> _reactivarPedido(
    PedidosListadoPedidoReactivado event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      await _repository.reactivarPedido(
        pedidoId: event.pedidoId,
        observacion: event.observacion,
      );
      final pedidos = await _repository.obtenerPedidosResumen();
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          message: 'Pedido reactivado correctamente.',
          limpiarError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo reactivar el pedido: $error',
          limpiarMessage: true,
        ),
      );
    }
  }

  void _cambiarFiltroRapido(
    PedidosListadoFiltroRapidoCambiado event,
    Emitter<PedidosListadoState> emit,
  ) {
    final filtro = event.value;
    if (filtro == 'Todos') {
      emit(
        state.copyWith(
          filtrosRapidos: const {'Todos'},
          limpiarError: true,
          limpiarMessage: true,
        ),
      );
      return;
    }

    final filtros = {...state.filtrosRapidos}..remove('Todos');
    if (filtros.contains(filtro)) {
      filtros.remove(filtro);
      emit(
        state.copyWith(
          filtrosRapidos: filtros.isEmpty ? const {'Todos'} : filtros,
          limpiarError: true,
          limpiarMessage: true,
        ),
      );
      return;
    }

    const estados = {
      'Pendiente',
      'En proceso',
      'Listo para entregar',
      'Entregado',
      'Cancelado',
    };
    if (estados.contains(filtro)) filtros.removeAll(estados);
    if (filtro == 'Con precio completo') {
      filtros.remove('Pendiente de valorización');
    }
    if (filtro == 'Pendiente de valorización') {
      filtros.remove('Con precio completo');
    }
    filtros.add(filtro);
    emit(
      state.copyWith(
        filtrosRapidos: filtros,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
  }
}
