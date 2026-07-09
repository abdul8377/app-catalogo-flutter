import '../entities/producto.dart';
import '../repositories/catalogo_repository.dart';

class ObtenerProductosUseCase {
  const ObtenerProductosUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<List<Producto>> call() {
    return _repository.obtenerProductos();
  }
}
