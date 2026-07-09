import '../entities/producto.dart';
import '../repositories/catalogo_repository.dart';

class ObtenerDetalleProductoUseCase {
  const ObtenerDetalleProductoUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<Producto?> call(String id) {
    return _repository.obtenerDetalleProducto(id);
  }
}
