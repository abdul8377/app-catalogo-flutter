import 'package:equatable/equatable.dart';

sealed class PedidosListadoEvent extends Equatable {
  const PedidosListadoEvent();

  @override
  List<Object?> get props => [];
}

class PedidosListadoStarted extends PedidosListadoEvent {
  const PedidosListadoStarted();
}

class PedidosListadoRecargado extends PedidosListadoEvent {
  const PedidosListadoRecargado();
}

class PedidosListadoBusquedaCambiada extends PedidosListadoEvent {
  const PedidosListadoBusquedaCambiada(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class PedidosListadoFiltroRapidoCambiado extends PedidosListadoEvent {
  const PedidosListadoFiltroRapidoCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class PedidosListadoFiltrosAvanzadosAplicados extends PedidosListadoEvent {
  const PedidosListadoFiltrosAvanzadosAplicados({
    this.estado,
    this.hoja,
    this.precio,
    this.sincronizacion,
    this.fechaInicio,
    this.fechaFin,
    this.cliente,
    this.vendedor,
    this.empresa,
    this.categoria,
    this.producto,
    this.cotizacion,
  });

  final String? estado;
  final String? hoja;
  final String? precio;
  final String? sincronizacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cliente;
  final String? vendedor;
  final String? empresa;
  final String? categoria;
  final String? producto;
  final String? cotizacion;

  @override
  List<Object?> get props => [
    estado,
    hoja,
    precio,
    sincronizacion,
    fechaInicio,
    fechaFin,
    cliente,
    vendedor,
    empresa,
    categoria,
    producto,
    cotizacion,
  ];
}

class PedidosListadoFiltrosLimpiados extends PedidosListadoEvent {
  const PedidosListadoFiltrosLimpiados();
}

class PedidosListadoOrdenCambiado extends PedidosListadoEvent {
  const PedidosListadoOrdenCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class PedidosListadoEstadoActualizado extends PedidosListadoEvent {
  const PedidosListadoEstadoActualizado({
    required this.pedidoId,
    required this.nuevoEstado,
    this.observacion = '',
  });

  final String pedidoId;
  final String nuevoEstado;
  final String observacion;

  @override
  List<Object?> get props => [pedidoId, nuevoEstado, observacion];
}

class PedidosListadoPedidoCancelado extends PedidosListadoEvent {
  const PedidosListadoPedidoCancelado({
    required this.pedidoId,
    required this.motivo,
  });

  final String pedidoId;
  final String motivo;

  @override
  List<Object?> get props => [pedidoId, motivo];
}

class PedidosListadoPedidoReactivado extends PedidosListadoEvent {
  const PedidosListadoPedidoReactivado({
    required this.pedidoId,
    this.observacion = '',
  });

  final String pedidoId;
  final String observacion;

  @override
  List<Object?> get props => [pedidoId, observacion];
}

class PedidosListadoSincronizacionReintentada extends PedidosListadoEvent {
  const PedidosListadoSincronizacionReintentada(this.pedidoId);

  final String pedidoId;

  @override
  List<Object?> get props => [pedidoId];
}
