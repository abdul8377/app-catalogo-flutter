import '../entities/producto_detalle.dart';
import '../repositories/catalogo_repository.dart';

class ObtenerDetalleProductoUseCase {
  const ObtenerDetalleProductoUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<ProductoDetalle?> call(String id) {
    return _repository.obtenerDetalleProducto(id);
  }
}
