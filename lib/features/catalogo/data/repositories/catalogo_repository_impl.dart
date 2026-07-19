import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/nuevo_producto.dart';
import '../../domain/entities/producto_resumen.dart';
import '../../domain/entities/producto_detalle.dart';
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
  Future<List<ProductoResumen>> obtenerProductos() =>
      localDatasource.obtenerProductos();
  @override
  Future<List<ProductoResumen>> buscarProductos(String query) =>
      localDatasource.buscarProductos(query);
  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) =>
      localDatasource.obtenerDetalleProducto(id);
  @override
  Future<CatalogoFormData> obtenerDatosFormulario() =>
      localDatasource.obtenerDatosFormulario();
  @override
  Future<void> guardarProducto(NuevoProducto producto) =>
      localDatasource.guardarProducto(producto);
  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) =>
      localDatasource.actualizarProducto(id, producto);
  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) =>
      localDatasource.cambiarEstadoProducto(id, activo: activo);
  Future<void> sincronizarCatalogo() => remoteDatasource.sincronizarCatalogo();
}
