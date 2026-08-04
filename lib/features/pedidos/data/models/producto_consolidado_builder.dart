part of '../datasources/pedidos_local_datasource.dart';

class _ProductoConsolidadoBuilder {
  _ProductoConsolidadoBuilder({
    required this.key,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.variante,
    required this.presentacion,
    required this.equivalencia,
    this.marca,
    this.empresa,
    this.categoria,
    this.subcategoria,
    this.unidadBase = 'UND',
    this.pendientePrecio = false,
    this.imagenPath,
  });

  final String key;
  final String productoId;
  final String codigo;
  final String nombre;
  final String? marca;
  final String? empresa;
  final String? categoria;
  final String? subcategoria;
  final String variante;
  final String presentacion;
  final String equivalencia;
  final String unidadBase;
  final String? imagenPath;
  bool pendientePrecio;
  int totalRequerido = 0;
  int totalPreparado = 0;
  final List<DistribucionPedido> distribucion = [];
  final List<PreparacionDisponible> disponibles = [];

  ProductoConsolidado build() => ProductoConsolidado(
    key: key,
    productoId: productoId,
    codigo: codigo,
    nombre: nombre,
    marca: marca,
    empresa: empresa,
    categoria: categoria,
    subcategoria: subcategoria,
    variante: variante,
    presentacion: presentacion,
    equivalencia: equivalencia,
    imagenPath: imagenPath,
    unidadBase: unidadBase,
    pendientePrecio: pendientePrecio,
    totalRequerido: totalRequerido,
    totalPreparado: totalPreparado,
    distribucion: distribucion,
    disponibles: disponibles,
  );
}
