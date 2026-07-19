import 'package:equatable/equatable.dart';

class ProductoResumen extends Equatable {
  const ProductoResumen({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.empresa,
    required this.marca,
    required this.categoria,
    required this.unidadVenta,
    required this.precio,
    required this.sinPrecio,
    required this.activo,
    required this.tipoRegistro,
    required this.atributosClave,
    this.creadoEn,
    this.imagenesPaths = const [],
    this.imagenPath,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String empresa;
  final String marca;
  final String categoria;
  final String unidadVenta;
  final double? precio;
  final bool sinPrecio;
  final bool activo;
  final String tipoRegistro;
  final List<String> atributosClave;
  final DateTime? creadoEn;
  final List<String> imagenesPaths;
  final String? imagenPath;

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    empresa,
    marca,
    categoria,
    unidadVenta,
    precio,
    sinPrecio,
    activo,
    imagenPath,
    tipoRegistro,
    atributosClave,
    creadoEn,
    imagenesPaths,
  ];
}
