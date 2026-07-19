import 'catalogo_form_data.dart';

class NuevoProducto {
  const NuevoProducto({
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
    this.imagenesPaths = const [],
    this.imagenPath,
    this.activo = true,
  });
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
  final List<String> imagenesPaths;
  final String? imagenPath;
  final bool activo;

  List<String> get imagenes => imagenesPaths.isNotEmpty
      ? imagenesPaths
      : imagenPath == null
      ? const []
      : [imagenPath!];
}
