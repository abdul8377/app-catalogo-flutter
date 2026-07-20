import 'package:equatable/equatable.dart';

sealed class ClientesEvent extends Equatable {
  const ClientesEvent();

  @override
  List<Object?> get props => [];
}

class ClientesStarted extends ClientesEvent {
  const ClientesStarted();
}

class ClientesRecargados extends ClientesEvent {
  const ClientesRecargados();
}

class ClientesBusquedaCambiada extends ClientesEvent {
  const ClientesBusquedaCambiada(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class ClientesFiltroRapidoCambiado extends ClientesEvent {
  const ClientesFiltroRapidoCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class ClientesFiltrosAvanzadosAplicados extends ClientesEvent {
  const ClientesFiltrosAvanzadosAplicados({required this.orden});

  final String orden;

  @override
  List<Object?> get props => [orden];
}

class ClientesFiltrosLimpiados extends ClientesEvent {
  const ClientesFiltrosLimpiados();
}

class ClientesOrdenCambiado extends ClientesEvent {
  const ClientesOrdenCambiado(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class ClientesVistaCambiada extends ClientesEvent {
  const ClientesVistaCambiada(this.vistaGrilla);

  final bool vistaGrilla;

  @override
  List<Object?> get props => [vistaGrilla];
}

class ClienteEstadoCambiado extends ClientesEvent {
  const ClienteEstadoCambiado(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
