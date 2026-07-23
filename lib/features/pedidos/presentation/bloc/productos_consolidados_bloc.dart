import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pedido.dart';
import '../../domain/entities/producto_consolidado.dart';
import '../../domain/repositories/pedidos_repository.dart';
import 'productos_consolidados_event.dart';
import 'productos_consolidados_state.dart';

class ProductosConsolidadosBloc
    extends Bloc<ProductosConsolidadosEvent, ProductosConsolidadosState> {
  ProductosConsolidadosBloc(this._repository, {String? initialHojaCodigo})
    : super(ProductosConsolidadosState.initial(hojaCodigo: initialHojaCodigo)) {
    on<ProductosConsolidadosStarted>(_iniciar);
    on<ProductosConsolidadosRecargados>(_recargar);
    on<ProductosConsolidadosBusquedaCambiada>(
      (event, emit) => emit(
        state.copyWith(
          busqueda: event.value,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<ProductosConsolidadosFiltrosAplicados>((event, emit) {
      final base = state.copyWith(limpiarFiltros: true);
      emit(
        base.copyWith(
          hojaCodigo: event.hojaCodigo,
          limpiarHoja: event.hojaCodigo == null,
          empresa: event.empresa,
          marca: event.marca,
          categoria: event.categoria,
          subcategoria: event.subcategoria,
          estadoPreparacion: event.estadoPreparacion,
          estadoPedido: event.estadoPedido,
          soloSinPrecio: event.soloSinPrecio,
          clearError: true,
          clearMessage: true,
        ),
      );
    });
    on<ProductosConsolidadosFiltrosLimpiados>(
      (_, emit) => emit(
        state.copyWith(
          busqueda: '',
          limpiarFiltros: true,
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
    on<ProductosConsolidadosOrdenCambiado>(
      (event, emit) => emit(state.copyWith(orden: event.value)),
    );
    on<ProductosConsolidadosPreparacionRegistrada>(_registrarPreparacion);
  }

  final PedidosRepository _repository;

  Future<void> _iniciar(
    ProductosConsolidadosStarted event,
    Emitter<ProductosConsolidadosState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));
    try {
      final results = await Future.wait([
        _repository.obtenerProductosConsolidados(),
        _repository.obtenerHojaActiva(),
      ]);
      final productos = results[0] as List<ProductoConsolidado>;
      final hoja = results[1] as HojaPedidoActiva?;
      emit(
        state.copyWith(
          loading: false,
          productos: productos,
          hojaCodigo: state.hojaCodigo ?? hoja?.codigo,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar el consolidado: $error',
        ),
      );
    }
  }

  Future<void> _recargar(
    ProductosConsolidadosRecargados event,
    Emitter<ProductosConsolidadosState> emit,
  ) async {
    try {
      final productos = await _repository.obtenerProductosConsolidados();
      emit(
        state.copyWith(
          productos: productos,
          clearError: true,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(error: 'No se pudo actualizar el consolidado: $error'),
      );
    }
  }

  Future<void> _registrarPreparacion(
    ProductosConsolidadosPreparacionRegistrada event,
    Emitter<ProductosConsolidadosState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearError: true, clearMessage: true));
    try {
      await _repository.registrarPreparacionProducto(event.preparacion);
      final productos = await _repository.obtenerProductosConsolidados();
      emit(
        state.copyWith(
          saving: false,
          productos: productos,
          message: 'Preparación registrada correctamente.',
          clearError: true,
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
}
