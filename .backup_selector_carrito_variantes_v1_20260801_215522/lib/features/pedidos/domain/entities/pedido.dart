import 'package:equatable/equatable.dart';

class HojaPedidoActiva extends Equatable {
  const HojaPedidoActiva({
    required this.id,
    required this.codigo,
    required this.estado,
  });

  final String id;
  final String codigo;
  final String estado;

  @override
  List<Object?> get props => [id, codigo, estado];
}

class ClientePedido extends Equatable {
  const ClientePedido({
    this.id,
    required this.nombre,
    required this.telefono,
    this.dni = '',
    this.ruc = '',
    this.tipoEntrega = 'entrega',
    this.direccion = '',
    this.referencia = '',
    this.fotoUbicacionPath,
    this.observaciones = '',
  });

  final String? id;
  final String nombre;
  final String telefono;
  final String dni;
  final String ruc;
  final String tipoEntrega;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final String observaciones;

  bool get requiereDireccion => true;

  @override
  List<Object?> get props => [
    id,
    nombre,
    telefono,
    dni,
    ruc,
    tipoEntrega,
    direccion,
    referencia,
    fotoUbicacionPath,
    observaciones,
  ];
}

class PedidoItem extends Equatable {
  const PedidoItem({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.equivalencia,
    required this.cantidad,
    required this.precioUnitario,
    this.opciones = const [],
    this.imagenPath,
  });

  final String productoId;
  final String codigo;
  final String nombre;
  final String presentacion;
  final String equivalencia;
  final int cantidad;
  final double? precioUnitario;
  final List<PresentacionPedidoOpcion> opciones;
  final String? imagenPath;

  double? get subtotal =>
      precioUnitario == null ? null : precioUnitario! * cantidad;

  PedidoItem copyWith({
    String? presentacion,
    String? equivalencia,
    int? cantidad,
    double? precioUnitario,
    bool limpiarPrecio = false,
    List<PresentacionPedidoOpcion>? opciones,
  }) => PedidoItem(
    productoId: productoId,
    codigo: codigo,
    nombre: nombre,
    presentacion: presentacion ?? this.presentacion,
    equivalencia: equivalencia ?? this.equivalencia,
    cantidad: cantidad ?? this.cantidad,
    precioUnitario: limpiarPrecio
        ? null
        : precioUnitario ?? this.precioUnitario,
    opciones: opciones ?? this.opciones,
    imagenPath: imagenPath,
  );

  @override
  List<Object?> get props => [
    productoId,
    codigo,
    nombre,
    presentacion,
    equivalencia,
    cantidad,
    precioUnitario,
    opciones,
    imagenPath,
  ];
}

class PresentacionPedidoOpcion extends Equatable {
  const PresentacionPedidoOpcion({
    required this.nombre,
    required this.equivalencia,
    required this.precio,
  });

  final String nombre;
  final String equivalencia;
  final double? precio;

  @override
  List<Object?> get props => [nombre, equivalencia, precio];
}

class PedidoRegistrado extends Equatable {
  const PedidoRegistrado({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.hojaCodigo,
    required this.estado,
  });

  final String id;
  final String codigo;
  final String cliente;
  final String hojaCodigo;
  final String estado;

  @override
  List<Object?> get props => [id, codigo, cliente, hojaCodigo, estado];
}
