import '../../domain/entities/producto.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../datasources/catalogo_local_datasource.dart';
import '../datasources/catalogo_remote_datasource.dart';

class CatalogoRepositoryImpl implements CatalogoRepository {
  const CatalogoRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  final CatalogoLocalDatasource localDatasource;
  final CatalogoRemoteDatasource remoteDatasource;

  @override
  Future<List<Producto>> obtenerProductos() {
    return localDatasource.obtenerProductos();
  }

  @override
  Future<List<Producto>> buscarProductos(String query) {
    return localDatasource.buscarProductos(query);
  }

  @override
  Future<Producto?> obtenerDetalleProducto(String id) {
    return localDatasource.obtenerDetalleProducto(id);
  }

  Future<void> sincronizarCatalogo() {
    return remoteDatasource.sincronizarCatalogo();
  }
}
