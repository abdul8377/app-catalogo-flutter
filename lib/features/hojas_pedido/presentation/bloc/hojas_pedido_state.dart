import 'package:equatable/equatable.dart';

import '../../domain/entities/hoja_pedido.dart';

class HojasPedidoState extends Equatable {
  const HojasPedidoState({
    required this.loading,
    required this.saving,
    required this.actualizando,
    required this.currentTab,
    required this.hojas,
    required this.busqueda,
    required this.filtro,
    required this.orden,
    this.error,
    this.message,
  });

  factory HojasPedidoState.initial() => const HojasPedidoState(
    loading: true,
    saving: false,
    actualizando: false,
    currentTab: 0,
    hojas: [],
    busqueda: '',
    filtro: 'Todas',
    orden: 'Más recientes',
  );

  final bool loading;
  final bool saving;
  final bool actualizando;
  final int currentTab;
  final List<HojaPedido> hojas;
  final String busqueda;
  final String filtro;
  final String orden;
  final String? error;
  final String? message;

  HojaPedido? get hojaActiva {
    for (final hoja in hojas) {
      if (hoja.abierta) return hoja;
    }
    return null;
  }

  List<HojaPedido> get historial {
    final query = busqueda.trim().toLowerCase();
    final now = DateTime.now();
    final result = hojas.where((hoja) {
      if (hoja.abierta) return false;
      final coincideBusqueda =
          query.isEmpty ||
          hoja.codigo.toLowerCase().contains(query) ||
          hoja.vendedor.toLowerCase().contains(query) ||
          hoja.referencia.toLowerCase().contains(query) ||
          hoja.pedidos.any(
            (pedido) =>
                pedido.codigo.toLowerCase().contains(query) ||
                pedido.cliente.toLowerCase().contains(query),
          ) ||
          hoja.productos.any(
            (producto) => producto.nombre.toLowerCase().contains(query),
          );
      if (!coincideBusqueda) return false;
      switch (filtro) {
        case 'Este mes':
          final fecha = hoja.fechaCierre ?? hoja.fechaApertura;
          return fecha.year == now.year && fecha.month == now.month;
        case 'Con precios pendientes':
          return hoja.pedidosPendientesPrecio > 0;
        case 'Con pedidos pendientes':
          return hoja.pedidosPendientes > 0 || hoja.pedidosEnProceso > 0;
        case 'Completamente entregadas':
          return hoja.totalPedidos > 0 &&
              hoja.pedidosEntregados == hoja.totalPedidos;
        case 'Sin sincronizar':
          return !hoja.sincronizado;
        default:
          return true;
      }
    }).toList();

    switch (orden) {
      case 'Más antiguas':
        result.sort((a, b) => a.fechaApertura.compareTo(b.fechaApertura));
      case 'Código':
        result.sort((a, b) => a.codigo.compareTo(b.codigo));
      case 'Mayor cantidad de pedidos':
        result.sort((a, b) => b.totalPedidos.compareTo(a.totalPedidos));
      case 'Mayor total conocido':
        result.sort((a, b) => b.subtotalConocido.compareTo(a.subtotalConocido));
      case 'Mayor cantidad de productos':
        result.sort(
          (a, b) =>
              b.totalProductosDiferentes.compareTo(a.totalProductosDiferentes),
        );
      default:
        result.sort((a, b) => b.fechaApertura.compareTo(a.fechaApertura));
    }
    return result;
  }

  HojasPedidoState copyWith({
    bool? loading,
    bool? saving,
    bool? actualizando,
    int? currentTab,
    List<HojaPedido>? hojas,
    String? busqueda,
    String? filtro,
    String? orden,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => HojasPedidoState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    actualizando: actualizando ?? this.actualizando,
    currentTab: currentTab ?? this.currentTab,
    hojas: hojas ?? this.hojas,
    busqueda: busqueda ?? this.busqueda,
    filtro: filtro ?? this.filtro,
    orden: orden ?? this.orden,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    saving,
    actualizando,
    currentTab,
    hojas,
    busqueda,
    filtro,
    orden,
    error,
    message,
  ];
}
