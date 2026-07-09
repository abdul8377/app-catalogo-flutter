import 'dart:async';

import '../../domain/usecases/buscar_productos_usecase.dart';
import '../../domain/usecases/obtener_productos_usecase.dart';
import 'catalogo_event.dart';
import 'catalogo_state.dart';

class CatalogoBloc {
  CatalogoBloc({
    required this.obtenerProductosUseCase,
    required this.buscarProductosUseCase,
  });

  final ObtenerProductosUseCase obtenerProductosUseCase;
  final BuscarProductosUseCase buscarProductosUseCase;
  final _stateController = StreamController<CatalogoState>.broadcast();

  CatalogoState _state = const CatalogoInitialState();

  CatalogoState get state => _state;

  Stream<CatalogoState> get stream => _stateController.stream;

  Future<void> add(CatalogoEvent event) async {
    _emit(const CatalogoLoadingState());

    try {
      switch (event) {
        case ObtenerProductosEvent():
          final productos = await obtenerProductosUseCase();
          _emit(CatalogoLoadedState(productos));
        case BuscarProductosEvent(:final query):
          final productos = await buscarProductosUseCase(query);
          _emit(CatalogoLoadedState(productos));
      }
    } catch (_) {
      _emit(const CatalogoErrorState('No se pudo cargar el catalogo.'));
    }
  }

  void dispose() {
    _stateController.close();
  }

  void _emit(CatalogoState state) {
    _state = state;
    _stateController.add(state);
  }
}
