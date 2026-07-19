import 'package:equatable/equatable.dart';

import '../../domain/entities/catalogo_form_data.dart';

sealed class ProductoFormEvent extends Equatable {
  const ProductoFormEvent();
  @override
  List<Object?> get props => [];
}

class ProductoFormStarted extends ProductoFormEvent {
  const ProductoFormStarted({this.productoId});
  final String? productoId;

  @override
  List<Object?> get props => [productoId];
}

class ProductoFormPasoSiguiente extends ProductoFormEvent {
  const ProductoFormPasoSiguiente();
}

class ProductoFormPasoAnterior extends ProductoFormEvent {
  const ProductoFormPasoAnterior();
}

class ProductoFormPasoSeleccionado extends ProductoFormEvent {
  const ProductoFormPasoSeleccionado(this.paso);
  final int paso;

  @override
  List<Object?> get props => [paso];
}

class ProductoFormClasificacionCambiada extends ProductoFormEvent {
  const ProductoFormClasificacionCambiada({
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
  });
  final String? empresa, marca, categoria, subcategoria;
  @override
  List<Object?> get props => [empresa, marca, categoria, subcategoria];
}

class ProductoFormFamiliaCambiada extends ProductoFormEvent {
  const ProductoFormFamiliaCambiada({
    this.codigo,
    this.nombre,
    this.descripcion,
  });
  final String? codigo, nombre, descripcion;
  @override
  List<Object?> get props => [codigo, nombre, descripcion];
}

class ProductoFormImagenCambiada extends ProductoFormEvent {
  const ProductoFormImagenCambiada(this.path);
  final String? path;

  @override
  List<Object?> get props => [path];
}

class ProductoFormImagenesAgregadas extends ProductoFormEvent {
  const ProductoFormImagenesAgregadas(this.paths);
  final List<String> paths;

  @override
  List<Object?> get props => [paths];
}

class ProductoFormImagenEliminada extends ProductoFormEvent {
  const ProductoFormImagenEliminada(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class ProductoFormImagenPrincipalCambiada extends ProductoFormEvent {
  const ProductoFormImagenPrincipalCambiada(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class ProductoFormTipoCambiado extends ProductoFormEvent {
  const ProductoFormTipoCambiado(this.tipo);
  final String tipo;
  @override
  List<Object?> get props => [tipo];
}

class ProductoFormAtributoCambiado extends ProductoFormEvent {
  const ProductoFormAtributoCambiado(this.nombre, this.valor);
  final String nombre, valor;
  @override
  List<Object?> get props => [nombre, valor];
}

class ProductoFormPresentacionAgregada extends ProductoFormEvent {
  const ProductoFormPresentacionAgregada(this.presentacion);
  final PresentacionProducto presentacion;
  @override
  List<Object?> get props => [presentacion];
}

class ProductoFormPresentacionEliminada extends ProductoFormEvent {
  const ProductoFormPresentacionEliminada(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class ProductoFormPrecioAgregado extends ProductoFormEvent {
  const ProductoFormPrecioAgregado(this.precio);
  final PrecioProducto precio;
  @override
  List<Object?> get props => [precio];
}

class ProductoFormPrecioEliminado extends ProductoFormEvent {
  const ProductoFormPrecioEliminado(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class ProductoFormEstadoCambiado extends ProductoFormEvent {
  const ProductoFormEstadoCambiado(this.activo);
  final bool activo;

  @override
  List<Object?> get props => [activo];
}

class ProductoFormGuardado extends ProductoFormEvent {
  const ProductoFormGuardado();
}
