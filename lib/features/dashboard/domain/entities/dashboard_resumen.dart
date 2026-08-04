import 'package:equatable/equatable.dart';

import 'dashboard_actividad.dart';
import 'dashboard_cliente.dart';
import 'dashboard_cotizacion.dart';
import 'dashboard_faltante.dart';
import 'dashboard_hoja_activa.dart';
import 'dashboard_pedido_listo.dart';
import 'dashboard_pedido_reciente.dart';
import 'dashboard_producto_top.dart';
import 'dashboard_sincronizacion.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.totalPedidos,
    required this.subtotalConocido,
    required this.pedidosPendientesValorizar,
    required this.totalClientes,
    required this.unidadesRequeridas,
    required this.unidadesPreparadas,
    required this.pedidosCargados,
    required this.pedidosEntregados,
    required this.pedidosListosCargar,
    required this.pedidosPreparacionParcial,
    required this.cotizacionesGeneradas,
    required this.cotizacionesBorradores,
    required this.pedidosPorEstado,
    required this.productosTop,
    required this.cotizaciones,
    required this.pedidosRecientes,
    required this.clientes,
    required this.actividad,
    required this.principalesFaltantes,
    required this.pedidosListos,
    required this.sincronizacion,
    this.hojaActiva,
  });

  const DashboardData.empty()
    : totalPedidos = 0,
      subtotalConocido = 0,
      pedidosPendientesValorizar = 0,
      totalClientes = 0,
      unidadesRequeridas = 0,
      unidadesPreparadas = 0,
      pedidosCargados = 0,
      pedidosEntregados = 0,
      pedidosListosCargar = 0,
      pedidosPreparacionParcial = 0,
      cotizacionesGeneradas = 0,
      cotizacionesBorradores = 0,
      pedidosPorEstado = const {
        'Pendiente': 0,
        'En proceso': 0,
        'Listo para entregar': 0,
        'Entregado': 0,
        'Cancelado': 0,
      },
      productosTop = const [],
      cotizaciones = const [],
      pedidosRecientes = const [],
      clientes = const [],
      actividad = const [],
      principalesFaltantes = const [],
      pedidosListos = const [],
      sincronizacion = const DashboardSincronizacion(),
      hojaActiva = null;

  final int totalPedidos;
  final double subtotalConocido;
  final int pedidosPendientesValorizar;
  final int totalClientes;
  final int unidadesRequeridas;
  final int unidadesPreparadas;
  final int pedidosCargados;
  final int pedidosEntregados;
  final int pedidosListosCargar;
  final int pedidosPreparacionParcial;
  final int cotizacionesGeneradas;
  final int cotizacionesBorradores;
  final Map<String, int> pedidosPorEstado;
  final List<DashboardProductoTop> productosTop;
  final List<DashboardCotizacion> cotizaciones;
  final List<DashboardPedidoReciente> pedidosRecientes;
  final List<DashboardCliente> clientes;
  final List<DashboardActividad> actividad;
  final List<DashboardFaltante> principalesFaltantes;
  final List<DashboardPedidoListo> pedidosListos;
  final DashboardSincronizacion sincronizacion;
  final DashboardHojaActiva? hojaActiva;

  int get presentacionesRequeridas => unidadesRequeridas;
  int get presentacionesPreparadas => unidadesPreparadas;
  int get presentacionesPendientes => unidadesPendientes;

  double get progresoPreparacion {
    if (unidadesRequeridas <= 0) return 0;
    return (unidadesPreparadas / unidadesRequeridas).clamp(0, 1).toDouble();
  }

  int get unidadesPendientes => (unidadesRequeridas - unidadesPreparadas)
      .clamp(0, unidadesRequeridas)
      .toInt();

  int get productosPendientesPreparacion =>
      principalesFaltantes.where((item) => item.cantidadPendiente > 0).length;

  @override
  List<Object?> get props => [
    totalPedidos,
    subtotalConocido,
    pedidosPendientesValorizar,
    totalClientes,
    unidadesRequeridas,
    unidadesPreparadas,
    pedidosCargados,
    pedidosEntregados,
    pedidosListosCargar,
    pedidosPreparacionParcial,
    cotizacionesGeneradas,
    cotizacionesBorradores,
    pedidosPorEstado,
    productosTop,
    cotizaciones,
    pedidosRecientes,
    clientes,
    actividad,
    principalesFaltantes,
    pedidosListos,
    sincronizacion,
    hojaActiva,
  ];
}
