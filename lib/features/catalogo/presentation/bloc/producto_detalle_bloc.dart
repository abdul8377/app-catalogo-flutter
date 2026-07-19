import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/producto_detalle.dart';
import '../../domain/repositories/catalogo_repository.dart';

sealed class ProductoDetalleEvent extends Equatable {
  const ProductoDetalleEvent();
  @override
  List<Object?> get props => [];
}

class ProductoDetalleSolicitado extends ProductoDetalleEvent {
  const ProductoDetalleSolicitado(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ProductoDetalleState extends Equatable {
  const ProductoDetalleState({
    required this.loading,
    this.producto,
    this.error,
  });
  const ProductoDetalleState.initial()
    : loading = true,
      producto = null,
      error = null;
  final bool loading;
  final ProductoDetalle? producto;
  final String? error;
  @override
  List<Object?> get props => [loading, producto, error];
}

class ProductoDetalleBloc
    extends Bloc<ProductoDetalleEvent, ProductoDetalleState> {
  ProductoDetalleBloc(this._repository)
    : super(const ProductoDetalleState.initial()) {
    on<ProductoDetalleSolicitado>(_cargar);
  }
  final CatalogoRepository _repository;

  Future<void> _cargar(
    ProductoDetalleSolicitado event,
    Emitter<ProductoDetalleState> emit,
  ) async {
    emit(const ProductoDetalleState.initial());
    try {
      final producto = await _repository.obtenerDetalleProducto(event.id);
      if (producto == null) {
        emit(
          const ProductoDetalleState(
            loading: false,
            error: 'El producto ya no existe.',
          ),
        );
      } else {
        emit(ProductoDetalleState(loading: false, producto: producto));
      }
    } catch (_) {
      emit(
        const ProductoDetalleState(
          loading: false,
          error: 'No se pudo cargar el detalle del producto.',
        ),
      );
    }
  }
}
