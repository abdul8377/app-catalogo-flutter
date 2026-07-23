import 'package:equatable/equatable.dart';

sealed class HojasPedidoEvent extends Equatable {
  const HojasPedidoEvent();

  @override
  List<Object?> get props => [];
}

class HojasPedidoStarted extends HojasPedidoEvent {
  const HojasPedidoStarted();
}

class HojasPedidoRecargadas extends HojasPedidoEvent {
  const HojasPedidoRecargadas();
}

class HojasPedidoTabCambiado extends HojasPedidoEvent {
  const HojasPedidoTabCambiado(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}

class HojasPedidoBusquedaCambiada extends HojasPedidoEvent {
  const HojasPedidoBusquedaCambiada(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class HojasPedidoFiltroCambiado extends HojasPedidoEvent {
  const HojasPedidoFiltroCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class HojasPedidoOrdenCambiado extends HojasPedidoEvent {
  const HojasPedidoOrdenCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class HojasPedidoCreada extends HojasPedidoEvent {
  const HojasPedidoCreada({
    required this.vendedor,
    this.referencia = '',
    this.observacion = '',
  });

  final String vendedor;
  final String referencia;
  final String observacion;

  @override
  List<Object?> get props => [vendedor, referencia, observacion];
}

class HojasPedidoCompletada extends HojasPedidoEvent {
  const HojasPedidoCompletada({
    required this.hojaId,
    required this.usuario,
    this.observacion = '',
  });

  final String hojaId;
  final String usuario;
  final String observacion;

  @override
  List<Object?> get props => [hojaId, usuario, observacion];
}
