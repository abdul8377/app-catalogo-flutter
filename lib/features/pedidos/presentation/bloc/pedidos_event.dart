import 'package:equatable/equatable.dart';

import '../../domain/entities/pedido.dart';

sealed class PedidosEvent extends Equatable {
  const PedidosEvent();
  @override
  List<Object?> get props => [];
}

class PedidosStarted extends PedidosEvent {
  const PedidosStarted();
}

class PedidosBusquedaCambiada extends PedidosEvent {
  const PedidosBusquedaCambiada(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PedidosFiltroPrecioCambiado extends PedidosEvent {
  const PedidosFiltroPrecioCambiado(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PedidosFiltrosAplicados extends PedidosEvent {
  const PedidosFiltrosAplicados({this.empresa, this.marca, this.categoria});
  final String? empresa;
  final String? marca;
  final String? categoria;
  @override
  List<Object?> get props => [empresa, marca, categoria];
}

class PedidosFiltrosLimpiados extends PedidosEvent {
  const PedidosFiltrosLimpiados();
}

class PedidosOrdenCambiado extends PedidosEvent {
  const PedidosOrdenCambiado(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class PedidosVistaCambiada extends PedidosEvent {
  const PedidosVistaCambiada(this.vistaGrilla);
  final bool vistaGrilla;
  @override
  List<Object?> get props => [vistaGrilla];
}

class PedidoProductoAgregado extends PedidosEvent {
  const PedidoProductoAgregado(this.item);
  final PedidoItem item;
  @override
  List<Object?> get props => [item];
}

class PedidoItemCantidadCambiada extends PedidosEvent {
  const PedidoItemCantidadCambiada(this.index, this.cantidad);
  final int index;
  final int cantidad;
  @override
  List<Object?> get props => [index, cantidad];
}

class PedidoItemPresentacionCambiada extends PedidosEvent {
  const PedidoItemPresentacionCambiada(this.index, this.presentacion);
  final int index;
  final String presentacion;
  @override
  List<Object?> get props => [index, presentacion];
}

class PedidoItemEliminado extends PedidosEvent {
  const PedidoItemEliminado(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class PedidoClienteBuscado extends PedidosEvent {
  const PedidoClienteBuscado(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class PedidoClienteSeleccionado extends PedidosEvent {
  const PedidoClienteSeleccionado(this.cliente);
  final ClientePedido cliente;
  @override
  List<Object?> get props => [cliente];
}

class PedidoClienteLimpiado extends PedidosEvent {
  const PedidoClienteLimpiado();
}

class PedidoConfirmado extends PedidosEvent {
  const PedidoConfirmado();
}

class PedidoNuevoSolicitado extends PedidosEvent {
  const PedidoNuevoSolicitado();
}

class PedidoHojaActivaCreada extends PedidosEvent {
  const PedidoHojaActivaCreada();
}
