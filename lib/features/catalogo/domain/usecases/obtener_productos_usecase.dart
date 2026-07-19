import '../entities/producto_resumen.dart';
import '../repositories/catalogo_repository.dart';

class ObtenerProductosUseCase {
  const ObtenerProductosUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<List<ProductoResumen>> call() {
    return _repository.obtenerProductos();
  }
}
