import '../entities/producto_resumen.dart';
import '../repositories/catalogo_repository.dart';

class BuscarProductosUseCase {
  const BuscarProductosUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<List<ProductoResumen>> call(String query) {
    return _repository.buscarProductos(query);
  }
}
