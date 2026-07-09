import '../entities/producto.dart';
import '../repositories/catalogo_repository.dart';

class BuscarProductosUseCase {
  const BuscarProductosUseCase(this._repository);

  final CatalogoRepository _repository;

  Future<List<Producto>> call(String query) {
    return _repository.buscarProductos(query);
  }
}
