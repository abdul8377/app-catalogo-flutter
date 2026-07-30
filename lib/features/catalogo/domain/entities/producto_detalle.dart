import 'package:equatable/equatable.dart';

import 'catalogo_form_data.dart';
import 'producto_variante.dart';

class ProductoDetalle extends Equatable {
  const ProductoDetalle({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.empresa,
    required this.marca,
    required this.categoria,
    required this.subcategoria,
    required this.tipoRegistro,
    required this.atributos,
    required this.presentaciones,
    required this.precios,
    required this.activo,
    required this.creadoEn,
    this.variantes = const [],
    this.imagenesPaths = const [],
    this.imagenPath,
    this.ventaLogisticaContenido,
    this.preciosConfigurados,
    this.imagenesConfiguradas,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String empresa;
  final String marca;
  final String categoria;
  final String subcategoria;
  final String tipoRegistro;
  final Map<String, String> atributos;
  final List<PresentacionProducto> presentaciones;
  final List<PrecioProducto> precios;
  final bool activo;
  final DateTime creadoEn;
  final List<ProductoVariante> variantes;
  final List<String> imagenesPaths;
  final String? imagenPath;
  final Map<String, dynamic>? ventaLogisticaContenido;
  final Map<String, dynamic>? preciosConfigurados;
  final Map<String, dynamic>? imagenesConfiguradas;

  bool get tienePrecio => precios.isNotEmpty;
  double? get precioBase => precios.isEmpty ? null : precios.first.valor;

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    descripcion,
    empresa,
    marca,
    categoria,
    subcategoria,
    tipoRegistro,
    atributos,
    presentaciones,
    precios,
    activo,
    creadoEn,
    variantes,
    imagenesPaths,
    imagenPath,
    ventaLogisticaContenido,
    preciosConfigurados,
    imagenesConfiguradas,
  ];
}
