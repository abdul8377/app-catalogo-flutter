class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.precio,
    this.descripcion,
  });

  final String id;
  final String nombre;
  final String categoriaId;
  final double precio;
  final String? descripcion;
}
