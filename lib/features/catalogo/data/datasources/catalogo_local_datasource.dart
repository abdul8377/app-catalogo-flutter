import '../models/producto_model.dart';

class CatalogoLocalDatasource {
  final List<ProductoModel> _productos = const [
    ProductoModel(
      id: '1',
      nombre: 'Producto demo',
      categoriaId: 'general',
      precio: 25,
      descripcion: 'Producto local de ejemplo.',
    ),
  ];

  Future<List<ProductoModel>> obtenerProductos() async {
    return _productos;
  }

  Future<List<ProductoModel>> buscarProductos(String query) async {
    final texto = query.trim().toLowerCase();
    if (texto.isEmpty) {
      return obtenerProductos();
    }

    return _productos
        .where((producto) => producto.nombre.toLowerCase().contains(texto))
        .toList();
  }

  Future<ProductoModel?> obtenerDetalleProducto(String id) async {
    for (final producto in _productos) {
      if (producto.id == id) {
        return producto;
      }
    }
    return null;
  }
}
