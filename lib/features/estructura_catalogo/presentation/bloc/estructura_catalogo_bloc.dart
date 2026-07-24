import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/estructura_catalogo_repository.dart';
import 'estructura_catalogo_event.dart';
import 'estructura_catalogo_state.dart';

class EstructuraCatalogoBloc
    extends Bloc<EstructuraCatalogoEvent, EstructuraCatalogoState> {
  EstructuraCatalogoBloc(this._repository)
    : super(EstructuraCatalogoState.initial()) {
    on<EstructuraCatalogoStarted>(_cargar);
    on<EstructuraCatalogoRecargada>(_cargar);
    on<EmpresaCatalogoGuardada>(_guardarEmpresa);
    on<MarcaCatalogoGuardada>(_guardarMarca);
    on<CategoriaCatalogoGuardada>(_guardarCategoria);
    on<RelacionesCatalogoGuardadas>(_guardarRelaciones);
    on<EstadoEstructuraCambiado>(_cambiarEstado);
    on<MensajeEstructuraConsumido>(
      (_, emit) =>
          emit(state.copyWith(limpiarError: true, limpiarMensaje: true)),
    );
  }

  final EstructuraCatalogoRepository _repository;

  Future<void> _cargar(
    EstructuraCatalogoEvent event,
    Emitter<EstructuraCatalogoState> emit,
  ) async {
    emit(
      state.copyWith(loading: true, limpiarError: true, limpiarMensaje: true),
    );
    try {
      final snapshot = await _repository.obtenerEstructura();
      emit(state.copyWith(loading: false, snapshot: snapshot));
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          error: _mensajeError(
            error,
            'No se pudo cargar la estructura del catálogo.',
          ),
        ),
      );
    }
  }

  Future<void> _guardarEmpresa(
    EmpresaCatalogoGuardada event,
    Emitter<EstructuraCatalogoState> emit,
  ) => _ejecutar(
    emit,
    () => _repository.guardarEmpresa(id: event.id, empresa: event.empresa),
    event.id == null
        ? 'Empresa registrada correctamente.'
        : 'Empresa actualizada correctamente.',
  );

  Future<void> _guardarMarca(
    MarcaCatalogoGuardada event,
    Emitter<EstructuraCatalogoState> emit,
  ) => _ejecutar(
    emit,
    () => _repository.guardarMarca(id: event.id, marca: event.marca),
    event.id == null
        ? 'Marca registrada correctamente.'
        : 'Marca actualizada correctamente.',
  );

  Future<void> _guardarCategoria(
    CategoriaCatalogoGuardada event,
    Emitter<EstructuraCatalogoState> emit,
  ) => _ejecutar(
    emit,
    () =>
        _repository.guardarCategoria(id: event.id, categoria: event.categoria),
    event.id == null
        ? 'Categoría registrada correctamente.'
        : 'Categoría actualizada correctamente.',
  );

  Future<void> _guardarRelaciones(
    RelacionesCatalogoGuardadas event,
    Emitter<EstructuraCatalogoState> emit,
  ) => _ejecutar(
    emit,
    () => _repository.guardarRelaciones(
      marcaId: event.marcaId,
      categoriaIds: event.categoriaIds,
    ),
    'Relaciones actualizadas correctamente.',
  );

  Future<void> _cambiarEstado(
    EstadoEstructuraCambiado event,
    Emitter<EstructuraCatalogoState> emit,
  ) => _ejecutar(
    emit,
    () => _repository.cambiarEstado(
      tipo: event.tipo,
      id: event.id,
      activo: event.activo,
    ),
    event.activo
        ? 'Registro activado correctamente.'
        : 'Registro desactivado correctamente.',
  );

  Future<void> _ejecutar(
    Emitter<EstructuraCatalogoState> emit,
    Future<void> Function() action,
    String success,
  ) async {
    emit(
      state.copyWith(saving: true, limpiarError: true, limpiarMensaje: true),
    );
    try {
      await action();
      final snapshot = await _repository.obtenerEstructura();
      emit(state.copyWith(saving: false, snapshot: snapshot, mensaje: success));
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: _mensajeError(error, 'No se pudieron guardar los cambios.'),
        ),
      );
    }
  }

  String _mensajeError(Object error, String fallback) {
    if (error is StateError) return error.message.toString();
    if (error is ArgumentError) return error.message?.toString() ?? fallback;
    return fallback;
  }
}
