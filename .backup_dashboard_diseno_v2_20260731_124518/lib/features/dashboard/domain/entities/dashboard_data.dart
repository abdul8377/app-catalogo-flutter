import 'package:equatable/equatable.dart';

enum DashboardPeriodoTipo { hojaActiva, hoy, semana, mes, personalizado }

class DashboardFiltro extends Equatable {
  const DashboardFiltro({
    this.periodo = DashboardPeriodoTipo.hojaActiva,
    this.fechaInicio,
    this.fechaFin,
  });

  final DashboardPeriodoTipo periodo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  String get etiqueta {
    switch (periodo) {
      case DashboardPeriodoTipo.hojaActiva:
        return 'Hoja activa';
      case DashboardPeriodoTipo.hoy:
        return 'Hoy';
      case DashboardPeriodoTipo.semana:
        return 'Esta semana';
      case DashboardPeriodoTipo.mes:
        return 'Este mes';
      case DashboardPeriodoTipo.personalizado:
        return 'Personalizado';
    }
  }

  @override
  List<Object?> get props => [periodo, fechaInicio, fechaFin];
}

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

class DashboardHojaActiva extends Equatable {
  const DashboardHojaActiva({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.vendedor,
    required this.fecha,
    required this.pedidos,
    required this.clientes,
    required this.productos,
    required this.subtotal,
    required this.pendientesPrecio,
  });

  final String id;
  final String codigo;
  final String estado;
  final String vendedor;
  final DateTime fecha;
  final int pedidos;
  final int clientes;
  final int productos;
  final double subtotal;
  final int pendientesPrecio;

  @override
  List<Object?> get props => [
    id,
    codigo,
    estado,
    vendedor,
    fecha,
    pedidos,
    clientes,
    productos,
    subtotal,
    pendientesPrecio,
  ];
}

class DashboardProductoTop extends Equatable {
  const DashboardProductoTop({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.marca,
    required this.unidadBase,
    required this.cantidadRequerida,
    required this.cantidadPreparada,
    required this.pedidos,
  });

  final String productoId;
  final String nombre;
  final String codigo;
  final String marca;
  final String unidadBase;
  final int cantidadRequerida;
  final int cantidadPreparada;
  final int pedidos;

  int get cantidadPendiente => (cantidadRequerida - cantidadPreparada)
      .clamp(0, cantidadRequerida)
      .toInt();

  double get progreso => cantidadRequerida <= 0
      ? 0
      : (cantidadPreparada / cantidadRequerida).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
    productoId,
    nombre,
    codigo,
    marca,
    unidadBase,
    cantidadRequerida,
    cantidadPreparada,
    pedidos,
  ];
}

class DashboardCotizacion extends Equatable {
  const DashboardCotizacion({
    required this.id,
    required this.pedidoId,
    required this.codigo,
    required this.pedidoCodigo,
    required this.cliente,
    required this.total,
    required this.estado,
    required this.fecha,
    required this.tienePdf,
  });

  final String id;
  final String pedidoId;
  final String codigo;
  final String pedidoCodigo;
  final String cliente;
  final double total;
  final String estado;
  final DateTime fecha;
  final bool tienePdf;

  bool get esBorrador => estado.trim().toLowerCase() == 'borrador';

  @override
  List<Object?> get props => [
    id,
    pedidoId,
    codigo,
    pedidoCodigo,
    cliente,
    total,
    estado,
    fecha,
    tienePdf,
  ];
}

class DashboardPedidoReciente extends Equatable {
  const DashboardPedidoReciente({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.productos,
    required this.total,
    required this.productosSinPrecio,
    required this.estado,
    required this.fecha,
    required this.sincronizado,
  });

  final String id;
  final String codigo;
  final String cliente;
  final int productos;
  final double total;
  final int productosSinPrecio;
  final String estado;
  final DateTime fecha;
  final bool sincronizado;

  bool get tienePrecioCompleto => productosSinPrecio == 0;

  @override
  List<Object?> get props => [
    id,
    codigo,
    cliente,
    productos,
    total,
    productosSinPrecio,
    estado,
    fecha,
    sincronizado,
  ];
}

class DashboardCliente extends Equatable {
  const DashboardCliente({
    required this.id,
    required this.nombre,
    required this.pedidos,
    required this.subtotalConocido,
    required this.ultimoPedido,
    required this.direccion,
  });

  final String id;
  final String nombre;
  final int pedidos;
  final double subtotalConocido;
  final DateTime ultimoPedido;
  final String direccion;

  @override
  List<Object?> get props => [
    id,
    nombre,
    pedidos,
    subtotalConocido,
    ultimoPedido,
    direccion,
  ];
}

class DashboardActividad extends Equatable {
  const DashboardActividad({
    required this.evento,
    required this.fecha,
    required this.tipo,
    this.detalle = '',
  });

  final String evento;
  final DateTime fecha;
  final String tipo;
  final String detalle;

  @override
  List<Object?> get props => [evento, fecha, tipo, detalle];
}

class DashboardFaltante extends Equatable {
  const DashboardFaltante({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.unidadBase,
    required this.cantidadPendiente,
    required this.pedidosAfectados,
  });

  final String productoId;
  final String nombre;
  final String codigo;
  final String unidadBase;
  final int cantidadPendiente;
  final int pedidosAfectados;

  @override
  List<Object?> get props => [
    productoId,
    nombre,
    codigo,
    unidadBase,
    cantidadPendiente,
    pedidosAfectados,
  ];
}

class DashboardPedidoListo extends Equatable {
  const DashboardPedidoListo({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.productos,
    required this.direccion,
  });

  final String id;
  final String codigo;
  final String cliente;
  final int productos;
  final String direccion;

  @override
  List<Object?> get props => [id, codigo, cliente, productos, direccion];
}

class DashboardSincronizacion extends Equatable {
  const DashboardSincronizacion({
    this.pedidosPendientes = 0,
    this.hojasPendientes = 0,
    this.operacionesEnCola = 0,
    this.errores = 0,
    this.ultimaSincronizacion,
  });

  final int pedidosPendientes;
  final int hojasPendientes;
  final int operacionesEnCola;
  final int errores;
  final DateTime? ultimaSincronizacion;

  int get totalPendiente =>
      pedidosPendientes + hojasPendientes + operacionesEnCola;

  bool get sincronizado => totalPendiente == 0 && errores == 0;

  @override
  List<Object?> get props => [
    pedidosPendientes,
    hojasPendientes,
    operacionesEnCola,
    errores,
    ultimaSincronizacion,
  ];
}
