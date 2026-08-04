part of '../pedidos_local_datasource.dart';

extension _PedidosEstadoHelpers on PedidosLocalDatasource {
  Future<void> _registrarHistorialPedido(
    Transaction txn, {
    required String pedidoId,
    required String evento,
    required String observacion,
    required String? responsable,
    required String creadoEn,
  }) async {
    await txn.insert('pedido_historial', {
      'id': const Uuid().v4(),
      'pedido_id': pedidoId,
      'evento': evento,
      'observacion': observacion.trim(),
      'responsable': responsable?.trim().isEmpty ?? true ? null : responsable,
      'creado_en': creadoEn,
    });
  }

  String _normalizarEstadoPedido(String estado) {
    final value = estado.trim().toLowerCase();
    if (value.contains('proceso')) return 'en_proceso';
    if (value.contains('listo')) return 'listo';
    if (value.contains('entregado')) return 'entregado';
    if (value.contains('cancelado')) return 'cancelado';
    return 'pendiente';
  }

  String _estadoPedidoLabel(String estado) {
    switch (estado) {
      case 'en_proceso':
        return 'En proceso';
      case 'listo':
        return 'Listo para entregar';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}
