import 'package:equatable/equatable.dart';

import '../../../domain/value_objects/catalogo_filtros.dart';

sealed class CatalogoEvent extends Equatable {
  const CatalogoEvent();
  @override
  List<Object?> get props => [];
}

class CatalogoStarted extends CatalogoEvent {
  const CatalogoStarted();
}

class CatalogoRecargado extends CatalogoEvent {
  const CatalogoRecargado();
}

class CatalogoBusquedaCambiada extends CatalogoEvent {
  const CatalogoBusquedaCambiada(this.texto);
  final String texto;
  @override
  List<Object?> get props => [texto];
}

class CatalogoFiltroRapidoCambiado extends CatalogoEvent {
  const CatalogoFiltroRapidoCambiado(this.filtro);
  final String filtro;
  @override
  List<Object?> get props => [filtro];
}

class CatalogoFiltrosAplicados extends CatalogoEvent {
  const CatalogoFiltrosAplicados(this.filtros);
  final CatalogoFiltros filtros;
  @override
  List<Object?> get props => [filtros];
}

class CatalogoFiltrosLimpiados extends CatalogoEvent {
  const CatalogoFiltrosLimpiados();
}

class CatalogoVistaCambiada extends CatalogoEvent {
  const CatalogoVistaCambiada(this.vistaGrilla);
  final bool vistaGrilla;
  @override
  List<Object?> get props => [vistaGrilla];
}

class CatalogoEstadoProductoCambiado extends CatalogoEvent {
  const CatalogoEstadoProductoCambiado(this.id, {required this.activo});
  final String id;
  final bool activo;
  @override
  List<Object?> get props => [id, activo];
}
