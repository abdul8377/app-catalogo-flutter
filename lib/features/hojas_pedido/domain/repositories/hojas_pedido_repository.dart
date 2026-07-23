import '../entities/hoja_pedido.dart';

abstract class HojasPedidoRepository {
  Future<List<HojaPedido>> obtenerHojas();

  Future<HojaPedido?> obtenerHoja(String id);

  Future<HojaPedido> crearHoja({
    required String vendedor,
    String referencia = '',
    String observacion = '',
  });

  Future<void> completarHoja({
    required String hojaId,
    required String usuario,
    String observacion = '',
  });
}
