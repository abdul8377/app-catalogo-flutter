import 'package:equatable/equatable.dart';

import '../../domain/entities/estructura_catalogo.dart';

sealed class EstructuraCatalogoEvent extends Equatable {
  const EstructuraCatalogoEvent();

  @override
  List<Object?> get props => [];
}

class EstructuraCatalogoStarted extends EstructuraCatalogoEvent {
  const EstructuraCatalogoStarted();
}

class EstructuraCatalogoRecargada extends EstructuraCatalogoEvent {
  const EstructuraCatalogoRecargada();
}

class EmpresaCatalogoGuardada extends EstructuraCatalogoEvent {
  const EmpresaCatalogoGuardada(this.empresa, {this.id});

  final int? id;
  final EmpresaCatalogoDraft empresa;

  @override
  List<Object?> get props => [id, empresa];
}

class MarcaCatalogoGuardada extends EstructuraCatalogoEvent {
  const MarcaCatalogoGuardada(this.marca, {this.id});

  final int? id;
  final MarcaCatalogoDraft marca;

  @override
  List<Object?> get props => [id, marca];
}

class CategoriaCatalogoGuardada extends EstructuraCatalogoEvent {
  const CategoriaCatalogoGuardada(this.categoria, {this.id});

  final int? id;
  final CategoriaCatalogoDraft categoria;

  @override
  List<Object?> get props => [id, categoria];
}

class RelacionesCatalogoGuardadas extends EstructuraCatalogoEvent {
  const RelacionesCatalogoGuardadas({
    required this.marcaId,
    required this.categoriaIds,
  });

  final int marcaId;
  final Set<int> categoriaIds;

  @override
  List<Object?> get props => [marcaId, categoriaIds];
}

class AtributosCategoriaGuardados extends EstructuraCatalogoEvent {
  const AtributosCategoriaGuardados({
    required this.categoriaId,
    required this.atributos,
  });

  final int categoriaId;
  final List<AtributoCategoriaCatalogo> atributos;

  @override
  List<Object?> get props => [categoriaId, atributos];
}

class EstadoEstructuraCambiado extends EstructuraCatalogoEvent {
  const EstadoEstructuraCambiado({
    required this.tipo,
    required this.id,
    required this.activo,
  });

  final String tipo;
  final int id;
  final bool activo;

  @override
  List<Object?> get props => [tipo, id, activo];
}

class MensajeEstructuraConsumido extends EstructuraCatalogoEvent {
  const MensajeEstructuraConsumido();
}
