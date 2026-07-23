import 'package:equatable/equatable.dart';

class HojaPedido extends Equatable {
  const HojaPedido({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.vendedor,
    required this.fechaApertura,
    required this.sincronizado,
    required this.totalPedidos,
    required this.totalClientes,
    required this.totalProductosDiferentes,
    required this.totalUnidades,
    required this.subtotalConocido,
    required this.pedidosPendientesPrecio,
    required this.pedidosPendientes,
    required this.pedidosEnProceso,
    required this.pedidosListos,
    required this.pedidosEntregados,
    required this.pedidosCancelados,
    required this.progresoPreparacion,
    required this.progresoCarga,
    required this.pedidos,
    required this.productos,
    required this.clientes,
    required this.historial,
    this.fechaCierre,
    this.referencia = '',
    this.observacion = '',
    this.usuarioCierre,
  });

  final String id;
  final String codigo;
  final String estado;
  final String vendedor;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final String referencia;
  final String observacion;
  final bool sincronizado;
  final String? usuarioCierre;
  final int totalPedidos;
  final int totalClientes;
  final int totalProductosDiferentes;
  final int totalUnidades;
  final double subtotalConocido;
  final int pedidosPendientesPrecio;
  final int pedidosPendientes;
  final int pedidosEnProceso;
  final int pedidosListos;
  final int pedidosEntregados;
  final int pedidosCancelados;
  final double progresoPreparacion;
  final double progresoCarga;
  final List<PedidoEnHoja> pedidos;
  final List<ProductoEnHoja> productos;
  final List<ClienteEnHoja> clientes;
  final List<HistorialHojaEntrada> historial;

  bool get abierta => estado.trim().toLowerCase() == 'abierta';

  List<PedidoEnHoja> get ultimosPedidos => pedidos.take(3).toList();

  List<ProductoEnHoja> get productosDestacados => productos.take(3).toList();

  int get pedidosPreparados =>
      pedidos.where((pedido) => pedido.progresoPreparacion >= 1).length;

  int get pedidosCargados => pedidos.where((pedido) => pedido.cargado).length;

  @override
  List<Object?> get props => [
    id,
    codigo,
    estado,
    vendedor,
    fechaApertura,
    fechaCierre,
    referencia,
    observacion,
    sincronizado,
    usuarioCierre,
    totalPedidos,
    totalClientes,
    totalProductosDiferentes,
    totalUnidades,
    subtotalConocido,
    pedidosPendientesPrecio,
    pedidosPendientes,
    pedidosEnProceso,
    pedidosListos,
    pedidosEntregados,
    pedidosCancelados,
    progresoPreparacion,
    progresoCarga,
    pedidos,
    productos,
    clientes,
    historial,
  ];
}

class PedidoEnHoja extends Equatable {
  const PedidoEnHoja({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.cliente,
    required this.cantidadProductos,
    required this.productosSinPrecio,
    required this.estado,
    required this.progresoPreparacion,
    required this.cargado,
    required this.fecha,
    this.total,
  });

  final String id;
  final String codigo;
  final String clienteId;
  final String cliente;
  final int cantidadProductos;
  final double? total;
  final int productosSinPrecio;
  final String estado;
  final double progresoPreparacion;
  final bool cargado;
  final DateTime fecha;

  bool get tienePrecio => productosSinPrecio == 0;

  String get estadoLabel {
    final value = estado.toLowerCase();
    if (value.contains('proceso')) return 'En proceso';
    if (value.contains('listo')) return 'Listo para entregar';
    if (value.contains('entregado')) return 'Entregado';
    if (value.contains('cancelado')) return 'Cancelado';
    return 'Pendiente';
  }

  @override
  List<Object?> get props => [
    id,
    codigo,
    clienteId,
    cliente,
    cantidadProductos,
    total,
    productosSinPrecio,
    estado,
    progresoPreparacion,
    cargado,
    fecha,
  ];
}

class ProductoEnHoja extends Equatable {
  const ProductoEnHoja({
    required this.key,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.equivalencia,
    required this.cantidadTotal,
    required this.cantidadPreparada,
    required this.pedidosQueLoIncluyen,
  });

  final String key;
  final String productoId;
  final String codigo;
  final String nombre;
  final String presentacion;
  final String equivalencia;
  final int cantidadTotal;
  final int cantidadPreparada;
  final int pedidosQueLoIncluyen;

  int get cantidadPendiente => cantidadTotal - cantidadPreparada;

  @override
  List<Object?> get props => [
    key,
    productoId,
    codigo,
    nombre,
    presentacion,
    equivalencia,
    cantidadTotal,
    cantidadPreparada,
    pedidosQueLoIncluyen,
  ];
}

class ClienteEnHoja extends Equatable {
  const ClienteEnHoja({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.cantidadPedidos,
    required this.cantidadProductos,
    required this.subtotalConocido,
  });

  final String id;
  final String nombre;
  final String telefono;
  final String direccion;
  final int cantidadPedidos;
  final int cantidadProductos;
  final double subtotalConocido;

  @override
  List<Object?> get props => [
    id,
    nombre,
    telefono,
    direccion,
    cantidadPedidos,
    cantidadProductos,
    subtotalConocido,
  ];
}

class HistorialHojaEntrada extends Equatable {
  const HistorialHojaEntrada({
    required this.fecha,
    required this.evento,
    this.responsable,
  });

  final DateTime fecha;
  final String evento;
  final String? responsable;

  @override
  List<Object?> get props => [fecha, evento, responsable];
}
