import 'package:equatable/equatable.dart';

import 'catalogo_form_data.dart';

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
    this.imagenesPaths = const [],
    this.imagenPath,
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
  final List<String> imagenesPaths;
  final String? imagenPath;

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
    imagenesPaths,
    imagenPath,
  ];
}
