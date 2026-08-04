import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/clientes_repository.dart';
import 'clientes_event.dart';
import 'clientes_state.dart';

class ClientesBloc extends Bloc<ClientesEvent, ClientesState> {
  ClientesBloc(this._repository) : super(ClientesState.initial()) {
    on<ClientesStarted>(_started);
    on<ClientesRecargados>(_recargar);
    on<ClientesBusquedaCambiada>(
      (event, emit) =>
          emit(state.copyWith(busqueda: event.value, limpiarError: true)),
    );
    on<ClientesFiltroRapidoCambiado>(_cambiarFiltroRapido);
    on<ClientesFiltrosAvanzadosAplicados>(
      (event, emit) =>
          emit(state.copyWith(orden: event.orden, limpiarError: true)),
    );
    on<ClientesFiltrosLimpiados>(
      (_, emit) => emit(
        state.copyWith(
          busqueda: '',
          filtrosRapidos: const {'Todos'},
          orden: 'Nombre A-Z',
          limpiarError: true,
        ),
      ),
    );
    on<ClientesOrdenCambiado>(
      (event, emit) => emit(state.copyWith(orden: event.value)),
    );
    on<ClientesVistaCambiada>(
      (event, emit) => emit(state.copyWith(vistaGrilla: event.vistaGrilla)),
    );
    on<ClienteEstadoCambiado>(_cambiarEstado);
  }

  final ClientesRepository _repository;

  Future<void> _started(
    ClientesStarted event,
    Emitter<ClientesState> emit,
  ) async {
    emit(state.copyWith(loading: true, limpiarError: true));
    try {
      final clientes = await _repository.obtenerClientes();
      emit(
        state.copyWith(loading: false, clientes: clientes, limpiarError: true),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar la lista de clientes.',
        ),
      );
    }
  }

  Future<void> _recargar(
    ClientesRecargados event,
    Emitter<ClientesState> emit,
  ) async {
    emit(state.copyWith(actualizando: true, limpiarError: true));
    try {
      final clientes = await _repository.obtenerClientes();
      emit(
        state.copyWith(
          actualizando: false,
          clientes: clientes,
          limpiarError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo actualizar la lista de clientes.',
        ),
      );
    }
  }

  void _cambiarFiltroRapido(
    ClientesFiltroRapidoCambiado event,
    Emitter<ClientesState> emit,
  ) {
    final filtros = {...state.filtrosRapidos};
    final filtro = event.value;
    if (filtro == 'Todos') {
      emit(state.copyWith(filtrosRapidos: const {'Todos'}));
      return;
    }

    filtros.remove('Todos');
    if (filtros.contains(filtro)) {
      filtros.remove(filtro);
      emit(
        state.copyWith(
          filtrosRapidos: filtros.isEmpty ? const {'Todos'} : filtros,
        ),
      );
      return;
    }

    switch (filtro) {
      case 'Activos':
        filtros.remove('Inactivos');
      case 'Inactivos':
        filtros.remove('Activos');
      case 'Con pedidos':
        filtros.remove('Sin pedidos');
      case 'Sin pedidos':
        filtros.remove('Con pedidos');
    }
    filtros.add(filtro);
    emit(state.copyWith(filtrosRapidos: filtros));
  }

  Future<void> _cambiarEstado(
    ClienteEstadoCambiado event,
    Emitter<ClientesState> emit,
  ) async {
    final cliente = state.clientes
        .where((cliente) => cliente.id == event.id)
        .firstOrNull;
    if (cliente == null) return;

    final nuevoEstado = !cliente.activo;
    final clientesOptimistas = state.clientes
        .map(
          (item) =>
              item.id == event.id ? item.copyWith(activo: nuevoEstado) : item,
        )
        .toList();
    emit(state.copyWith(clientes: clientesOptimistas, limpiarError: true));

    try {
      await _repository.cambiarEstadoCliente(event.id, activo: nuevoEstado);
    } catch (_) {
      emit(
        state.copyWith(
          clientes: state.clientes
              .map(
                (item) => item.id == event.id
                    ? item.copyWith(activo: cliente.activo)
                    : item,
              )
              .toList(),
          error: 'No se pudo cambiar el estado del cliente.',
        ),
      );
    }
  }
}
