import 'package:equatable/equatable.dart';

import '../../domain/entities/estructura_catalogo.dart';

class EstructuraCatalogoState extends Equatable {
  const EstructuraCatalogoState({
    required this.loading,
    required this.saving,
    required this.snapshot,
    this.error,
    this.mensaje,
  });

  factory EstructuraCatalogoState.initial() => const EstructuraCatalogoState(
    loading: true,
    saving: false,
    snapshot: EstructuraCatalogoSnapshot(
      empresas: [],
      marcas: [],
      categorias: [],
      relaciones: [],
    ),
  );

  final bool loading;
  final bool saving;
  final EstructuraCatalogoSnapshot snapshot;
  final String? error;
  final String? mensaje;

  EstructuraCatalogoState copyWith({
    bool? loading,
    bool? saving,
    EstructuraCatalogoSnapshot? snapshot,
    String? error,
    String? mensaje,
    bool limpiarError = false,
    bool limpiarMensaje = false,
  }) => EstructuraCatalogoState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    snapshot: snapshot ?? this.snapshot,
    error: limpiarError ? null : error ?? this.error,
    mensaje: limpiarMensaje ? null : mensaje ?? this.mensaje,
  );

  @override
  List<Object?> get props => [loading, saving, snapshot, error, mensaje];
}
