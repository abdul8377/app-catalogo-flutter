import 'package:equatable/equatable.dart';

import '../../domain/entities/producto_consolidado.dart';

sealed class ProductosConsolidadosEvent extends Equatable {
  const ProductosConsolidadosEvent();

  @override
  List<Object?> get props => [];
}

class ProductosConsolidadosStarted extends ProductosConsolidadosEvent {
  const ProductosConsolidadosStarted();
}

class ProductosConsolidadosRecargados extends ProductosConsolidadosEvent {
  const ProductosConsolidadosRecargados();
}

class ProductosConsolidadosBusquedaCambiada extends ProductosConsolidadosEvent {
  const ProductosConsolidadosBusquedaCambiada(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class ProductosConsolidadosFiltrosAplicados extends ProductosConsolidadosEvent {
  const ProductosConsolidadosFiltrosAplicados({
    this.hojaCodigo,
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
    this.estadoPreparacion,
    this.estadoPedido,
    this.soloSinPrecio = false,
  });

  final String? hojaCodigo;
  final String? empresa;
  final String? marca;
  final String? categoria;
  final String? subcategoria;
  final String? estadoPreparacion;
  final String? estadoPedido;
  final bool soloSinPrecio;

  @override
  List<Object?> get props => [
    hojaCodigo,
    empresa,
    marca,
    categoria,
    subcategoria,
    estadoPreparacion,
    estadoPedido,
    soloSinPrecio,
  ];
}

class ProductosConsolidadosFiltrosLimpiados extends ProductosConsolidadosEvent {
  const ProductosConsolidadosFiltrosLimpiados();
}

class ProductosConsolidadosOrdenCambiado extends ProductosConsolidadosEvent {
  const ProductosConsolidadosOrdenCambiado(this.value);
  final String value;

  @override
  List<Object?> get props => [value];
}

class ProductosConsolidadosPreparacionRegistrada
    extends ProductosConsolidadosEvent {
  const ProductosConsolidadosPreparacionRegistrada(this.preparacion);
  final PreparacionProductoDraft preparacion;

  @override
  List<Object?> get props => [preparacion];
}
