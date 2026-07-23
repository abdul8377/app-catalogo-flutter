import '../../domain/entities/hoja_pedido.dart';
import '../../domain/repositories/hojas_pedido_repository.dart';
import '../datasources/hojas_pedido_local_datasource.dart';

class HojasPedidoRepositoryImpl implements HojasPedidoRepository {
  const HojasPedidoRepositoryImpl(this.localDatasource);

  final HojasPedidoLocalDatasource localDatasource;

  @override
  Future<List<HojaPedido>> obtenerHojas() => localDatasource.obtenerHojas();

  @override
  Future<HojaPedido?> obtenerHoja(String id) => localDatasource.obtenerHoja(id);

  @override
  Future<HojaPedido> crearHoja({
    required String vendedor,
    String referencia = '',
    String observacion = '',
  }) => localDatasource.crearHoja(
    vendedor: vendedor,
    referencia: referencia,
    observacion: observacion,
  );

  @override
  Future<void> completarHoja({
    required String hojaId,
    required String usuario,
    String observacion = '',
  }) => localDatasource.completarHoja(
    hojaId: hojaId,
    usuario: usuario,
    observacion: observacion,
  );
}
