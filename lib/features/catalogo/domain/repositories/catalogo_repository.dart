import '../entities/catalogo_form_data.dart';
import '../entities/nuevo_producto.dart';
import '../entities/producto_resumen.dart';
import '../entities/producto_detalle.dart';

abstract class CatalogoRepository {
  Future<List<ProductoResumen>> obtenerProductos();
  Future<List<ProductoResumen>> buscarProductos(String query);
  Future<ProductoDetalle?> obtenerDetalleProducto(String id);
  Future<CatalogoFormData> obtenerDatosFormulario();
  Future<void> guardarProducto(NuevoProducto producto);
  Future<void> actualizarProducto(String id, NuevoProducto producto);
  Future<void> cambiarEstadoProducto(String id, {required bool activo});
}
