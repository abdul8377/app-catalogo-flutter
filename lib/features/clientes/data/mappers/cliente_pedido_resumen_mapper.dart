import '../../domain/entities/cliente_pedido_resumen.dart';
import '../models/cliente_pedido_resumen_local_model.dart';

abstract final class ClientePedidoResumenMapper {
  static ClientePedidoResumen toEntity(ClientePedidoResumenLocalModel model) =>
      ClientePedidoResumen(
        id: model.id,
        codigo: model.codigo,
        fecha: model.fecha,
        estado: model.estado,
        cantidadProductos: model.cantidadProductos,
        total: model.total,
        totalParcial: model.totalParcial,
      );
}
