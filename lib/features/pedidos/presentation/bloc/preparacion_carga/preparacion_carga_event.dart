import 'package:equatable/equatable.dart';

import '../../../domain/entities/producto_consolidado.dart';
import 'preparacion_carga_state.dart';

sealed class PreparacionCargaEvent extends Equatable {
  const PreparacionCargaEvent();

  @override
  List<Object?> get props => [];
}

class PreparacionCargaStarted extends PreparacionCargaEvent {
  const PreparacionCargaStarted();
}

class PreparacionCargaRecargada extends PreparacionCargaEvent {
  const PreparacionCargaRecargada();
}

class PreparacionCargaSubTabCambiada extends PreparacionCargaEvent {
  const PreparacionCargaSubTabCambiada(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}

class PreparacionCargaModoAgrupacionCambiado extends PreparacionCargaEvent {
  const PreparacionCargaModoAgrupacionCambiado(this.modo);

  final PreparacionModoAgrupacion modo;

  @override
  List<Object?> get props => [modo];
}

class PreparacionCargaPreparacionRegistrada extends PreparacionCargaEvent {
  const PreparacionCargaPreparacionRegistrada(this.preparacion);

  final PreparacionProductoDraft preparacion;

  @override
  List<Object?> get props => [preparacion];
}

class PreparacionCargaPedidoCargado extends PreparacionCargaEvent {
  const PreparacionCargaPedidoCargado({
    required this.pedidoId,
    required this.paquetes,
    this.observacion = '',
  });

  final String pedidoId;
  final int paquetes;
  final String observacion;

  @override
  List<Object?> get props => [pedidoId, paquetes, observacion];
}
