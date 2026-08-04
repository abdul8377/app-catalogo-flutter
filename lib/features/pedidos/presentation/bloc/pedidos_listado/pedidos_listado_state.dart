import 'package:equatable/equatable.dart';

import '../../../domain/entities/pedido_resumen.dart';

class PedidosListadoState extends Equatable {
  const PedidosListadoState({
    required this.loading,
    required this.actualizando,
    required this.pedidos,
    required this.busqueda,
    required this.filtrosRapidos,
    required this.orden,
    this.estado,
    this.hoja,
    this.precio,
    this.sincronizacion,
    this.hojaActivaCodigo,
    this.fechaInicio,
    this.fechaFin,
    this.cliente,
    this.vendedor,
    this.empresa,
    this.categoria,
    this.producto,
    this.cotizacion,
    this.error,
    this.message,
  });

  factory PedidosListadoState.initial() => const PedidosListadoState(
    loading: true,
    actualizando: false,
    pedidos: [],
    busqueda: '',
    filtrosRapidos: {'Todos'},
    orden: 'Más recientes',
  );

  final bool loading;
  final bool actualizando;
  final List<PedidoResumen> pedidos;
  final String busqueda;
  final Set<String> filtrosRapidos;
  final String orden;
  final String? estado;
  final String? hoja;
  final String? precio;
  final String? sincronizacion;
  final String? hojaActivaCodigo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cliente;
  final String? vendedor;
  final String? empresa;
  final String? categoria;
  final String? producto;
  final String? cotizacion;
  final String? error;
  final String? message;

  List<PedidoResumen> get pedidosFiltrados {
    final query = busqueda.trim().toLowerCase();
    final result = pedidos.where((pedido) {
      final coincideTexto =
          query.isEmpty ||
          pedido.codigo.toLowerCase().contains(query) ||
          pedido.clienteNombre.toLowerCase().contains(query) ||
          pedido.telefono.toLowerCase().contains(query) ||
          pedido.dni.toLowerCase().contains(query) ||
          pedido.ruc.toLowerCase().contains(query) ||
          pedido.direccion.toLowerCase().contains(query) ||
          pedido.referencia.toLowerCase().contains(query) ||
          pedido.hojaCodigo.toLowerCase().contains(query) ||
          pedido.productosResumen.any(
            (producto) => producto.toLowerCase().contains(query),
          );
      final coincideRapidos =
          filtrosRapidos.contains('Todos') ||
          ((!filtrosRapidos.contains('Pendiente') ||
                  pedido.estadoNormalizado == 'pendiente') &&
              (!filtrosRapidos.contains('En proceso') ||
                  pedido.estadoNormalizado == 'en_proceso') &&
              (!filtrosRapidos.contains('Listo para entregar') ||
                  pedido.estadoNormalizado == 'listo') &&
              (!filtrosRapidos.contains('Entregado') ||
                  pedido.estadoNormalizado == 'entregado') &&
              (!filtrosRapidos.contains('Cancelado') ||
                  pedido.estadoNormalizado == 'cancelado') &&
              (!filtrosRapidos.contains('Con precio completo') ||
                  pedido.productosSinPrecio == 0) &&
              (!filtrosRapidos.contains('Pendiente de valorización') ||
                  pedido.productosSinPrecio > 0) &&
              (!filtrosRapidos.contains('Sin sincronizar') ||
                  !pedido.sincronizado ||
                  pedido.guardadoLocal));
      final fechaPedido = DateTime(
        pedido.fecha.year,
        pedido.fecha.month,
        pedido.fecha.day,
      );
      final inicio = fechaInicio == null
          ? null
          : DateTime(fechaInicio!.year, fechaInicio!.month, fechaInicio!.day);
      final fin = fechaFin == null
          ? null
          : DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day);
      final clienteQuery = cliente?.trim().toLowerCase();
      final vendedorQuery = vendedor?.trim().toLowerCase();
      final empresaQuery = empresa?.trim().toLowerCase();
      final categoriaQuery = categoria?.trim().toLowerCase();
      final productoQuery = producto?.trim().toLowerCase();
      return coincideTexto &&
          coincideRapidos &&
          (estado == null || pedido.estadoNormalizado == estado) &&
          (hoja == null || pedido.hojaCodigo == hoja) &&
          (precio == null ||
              (precio == 'completo' && pedido.productosSinPrecio == 0) ||
              (precio == 'pendiente' && pedido.productosSinPrecio > 0)) &&
          (sincronizacion == null ||
              (sincronizacion == 'sincronizado' && pedido.sincronizado) ||
              (sincronizacion == 'local' && pedido.guardadoLocal) ||
              (sincronizacion == 'error' &&
                  !pedido.sincronizado &&
                  !pedido.guardadoLocal)) &&
          (inicio == null || !fechaPedido.isBefore(inicio)) &&
          (fin == null || !fechaPedido.isAfter(fin)) &&
          (clienteQuery == null ||
              clienteQuery.isEmpty ||
              pedido.clienteNombre.toLowerCase().contains(clienteQuery)) &&
          (vendedorQuery == null ||
              vendedorQuery.isEmpty ||
              pedido.vendedor.toLowerCase().contains(vendedorQuery)) &&
          (empresaQuery == null ||
              empresaQuery.isEmpty ||
              pedido.empresas.any(
                (value) => value.toLowerCase().contains(empresaQuery),
              ) ||
              pedido.marcas.any(
                (value) => value.toLowerCase().contains(empresaQuery),
              )) &&
          (categoriaQuery == null ||
              categoriaQuery.isEmpty ||
              pedido.categorias.any(
                (value) => value.toLowerCase().contains(categoriaQuery),
              )) &&
          (productoQuery == null ||
              productoQuery.isEmpty ||
              pedido.productosResumen.any(
                (value) => value.toLowerCase().contains(productoQuery),
              )) &&
          (cotizacion == null ||
              (cotizacion == 'generada' && pedido.cotizacionesGeneradas > 0) ||
              (cotizacion == 'no_generada' &&
                  pedido.cotizacionesGeneradas == 0));
    }).toList();

    switch (orden) {
      case 'Más antiguos':
        result.sort((a, b) => a.fecha.compareTo(b.fecha));
      case 'Código':
        result.sort((a, b) => a.codigo.compareTo(b.codigo));
      case 'Cliente A-Z':
        result.sort((a, b) => a.clienteNombre.compareTo(b.clienteNombre));
      case 'Estado':
        result.sort((a, b) => a.estadoLabel.compareTo(b.estadoLabel));
      case 'Mayor total':
        result.sort((a, b) => b.subtotalConocido.compareTo(a.subtotalConocido));
      case 'Menor total':
        result.sort((a, b) => a.subtotalConocido.compareTo(b.subtotalConocido));
      case 'Pendientes de precio primero':
        result.sort(
          (a, b) => b.productosSinPrecio.compareTo(a.productosSinPrecio),
        );
      case 'Pendientes de sincronización primero':
        result.sort((a, b) {
          final aPendiente = !a.sincronizado || a.guardadoLocal;
          final bPendiente = !b.sincronizado || b.guardadoLocal;
          return (bPendiente ? 1 : 0).compareTo(aPendiente ? 1 : 0);
        });
      default:
        result.sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    return result;
  }

  List<String> get hojasDisponibles => ({
    if (hojaActivaCodigo != null && hojaActivaCodigo!.isNotEmpty)
      hojaActivaCodigo!,
    for (final pedido in pedidos) pedido.hojaCodigo,
  }.toList()..sort());

  List<PedidoResumen> get pedidosHojaResumen {
    final codigo = hoja ?? hojaActivaCodigo;
    if (codigo == null) return const [];
    return pedidos.where((pedido) => pedido.hojaCodigo == codigo).toList();
  }

  int countEstado(String estadoKey) => pedidosHojaResumen
      .where((pedido) => pedido.estadoNormalizado == estadoKey)
      .length;

  int get countPendientesPrecio => pedidosHojaResumen
      .where((pedido) => pedido.productosSinPrecio > 0)
      .length;

  int get filtrosActivos =>
      [
        estado,
        precio,
        sincronizacion,
        cliente,
        vendedor,
        empresa,
        categoria,
        producto,
        cotizacion,
      ].whereType<String>().length +
      (fechaInicio == null ? 0 : 1) +
      (fechaFin == null ? 0 : 1) +
      (hoja != null && hoja != hojaActivaCodigo ? 1 : 0) +
      (filtrosRapidos.contains('Todos') ? 0 : filtrosRapidos.length);

  PedidosListadoState copyWith({
    bool? loading,
    bool? actualizando,
    List<PedidoResumen>? pedidos,
    String? busqueda,
    Set<String>? filtrosRapidos,
    String? orden,
    String? estado,
    String? hoja,
    String? precio,
    String? sincronizacion,
    String? hojaActivaCodigo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? cliente,
    String? vendedor,
    String? empresa,
    String? categoria,
    String? producto,
    String? cotizacion,
    bool limpiarAvanzados = false,
    String? error,
    bool limpiarError = false,
    String? message,
    bool limpiarMessage = false,
  }) => PedidosListadoState(
    loading: loading ?? this.loading,
    actualizando: actualizando ?? this.actualizando,
    pedidos: pedidos ?? this.pedidos,
    busqueda: busqueda ?? this.busqueda,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
    orden: orden ?? this.orden,
    estado: limpiarAvanzados ? null : estado ?? this.estado,
    hoja: limpiarAvanzados ? null : hoja ?? this.hoja,
    precio: limpiarAvanzados ? null : precio ?? this.precio,
    sincronizacion: limpiarAvanzados
        ? null
        : sincronizacion ?? this.sincronizacion,
    hojaActivaCodigo: hojaActivaCodigo ?? this.hojaActivaCodigo,
    fechaInicio: limpiarAvanzados ? null : fechaInicio ?? this.fechaInicio,
    fechaFin: limpiarAvanzados ? null : fechaFin ?? this.fechaFin,
    cliente: limpiarAvanzados ? null : cliente ?? this.cliente,
    vendedor: limpiarAvanzados ? null : vendedor ?? this.vendedor,
    empresa: limpiarAvanzados ? null : empresa ?? this.empresa,
    categoria: limpiarAvanzados ? null : categoria ?? this.categoria,
    producto: limpiarAvanzados ? null : producto ?? this.producto,
    cotizacion: limpiarAvanzados ? null : cotizacion ?? this.cotizacion,
    error: limpiarError ? null : error ?? this.error,
    message: limpiarMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    actualizando,
    pedidos,
    busqueda,
    filtrosRapidos,
    orden,
    estado,
    hoja,
    precio,
    sincronizacion,
    hojaActivaCodigo,
    fechaInicio,
    fechaFin,
    cliente,
    vendedor,
    empresa,
    categoria,
    producto,
    cotizacion,
    error,
    message,
  ];
}
