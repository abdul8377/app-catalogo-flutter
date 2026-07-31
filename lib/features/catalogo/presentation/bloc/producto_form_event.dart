import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/producto_variante.dart';
import '../widgets/paso4_venta_logistica_contenido.dart';
import '../widgets/paso5_precios_corregido.dart';
import '../widgets/paso6_imagenes_corregido.dart';
import '../widgets/paso7_revisar_activar_corregido.dart';

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

class ProductoFormImagenReemplazada extends ProductoFormEvent {
  const ProductoFormImagenReemplazada(this.index, this.path);

  final int index;
  final String path;

  @override
  List<Object?> get props => [index, path];
}

class ProductoFormImagenReordenada extends ProductoFormEvent {
  const ProductoFormImagenReordenada(this.desde, this.hasta);

  final int desde;
  final int hasta;

  @override
  List<Object?> get props => [desde, hasta];
}

class ProductoFormImagenesConfiguradasCambiadas extends ProductoFormEvent {
  const ProductoFormImagenesConfiguradasCambiadas(
    this.draft, {
    this.continuar = false,
  });

  final Step6ImagesDraft draft;
  final bool continuar;

  @override
  List<Object?> get props => [draft, continuar];
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

class ProductoFormVarianteGuardada extends ProductoFormEvent {
  const ProductoFormVarianteGuardada(this.variante);
  final ProductoVariante variante;

  @override
  List<Object?> get props => [variante];
}

class ProductoFormVariantesReemplazadas extends ProductoFormEvent {
  const ProductoFormVariantesReemplazadas(this.variantes);
  final List<ProductoVariante> variantes;

  @override
  List<Object?> get props => [variantes];
}

class ProductoFormMatrizResumenCambiado extends ProductoFormEvent {
  const ProductoFormMatrizResumenCambiado({
    required this.total,
    required this.excluidas,
  });

  final int total;
  final int excluidas;

  @override
  List<Object?> get props => [total, excluidas];
}

class ProductoFormVarianteEliminada extends ProductoFormEvent {
  const ProductoFormVarianteEliminada(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class ProductoFormEdicionVarianteCambiada extends ProductoFormEvent {
  const ProductoFormEdicionVarianteCambiada(this.pendiente);
  final bool pendiente;

  @override
  List<Object?> get props => [pendiente];
}

class ProductoFormErrorLimpiado extends ProductoFormEvent {
  const ProductoFormErrorLimpiado();
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

class ProductoFormVentaLogisticaCambiada extends ProductoFormEvent {
  const ProductoFormVentaLogisticaCambiada(
    this.draft, {
    this.continuar = false,
  });

  final Step4SalesDraft draft;
  final bool continuar;

  @override
  List<Object?> get props => [draft, continuar];
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

class ProductoFormPreciosConfiguradosCambiados extends ProductoFormEvent {
  const ProductoFormPreciosConfiguradosCambiados(
    this.draft, {
    this.continuar = false,
  });

  final PricingStep5Draft draft;
  final bool continuar;

  @override
  List<Object?> get props => [draft, continuar];
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

class ProductoFormActivadoDesdeRevision extends ProductoFormEvent {
  const ProductoFormActivadoDesdeRevision({
    required this.request,
    required this.completer,
  });

  final Step7ActivationRequest request;
  final Completer<Step7ActivationResult> completer;

  @override
  List<Object?> get props => [request, completer];
}
