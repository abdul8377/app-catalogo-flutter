import '../entities/producto.dart';

abstract class CatalogoRepository {
  Future<List<Producto>> obtenerProductos();

  Future<List<Producto>> buscarProductos(String query);

  Future<Producto?> obtenerDetalleProducto(String id);
}
