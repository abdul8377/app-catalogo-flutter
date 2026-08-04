import 'package:equatable/equatable.dart';

class AtributoDef extends Equatable {
  const AtributoDef({
    required this.nombre,
    required this.tipo,
    required this.esVariante,
    this.id = '',
    this.clave = '',
    this.requerido = false,
    this.opciones = const [],
    this.unidades = const [],
    this.unidadPredeterminada,
    this.minimo,
    this.maximo,
    this.decimales = 0,
    this.maximoSelecciones,
    this.magnitud,
    this.nivelCaptura = 'familia',
    this.puedeSerEje = false,
    this.ayuda = '',
    this.ejemplo = '',
  });

  final String nombre;
  final String tipo;
  final bool esVariante;
  final String id;
  final String clave;
  final bool requerido;
  final List<String> opciones;
  final List<String> unidades;
  final String? unidadPredeterminada;
  final double? minimo;
  final double? maximo;
  final int decimales;
  final int? maximoSelecciones;
  final String? magnitud;
  final String nivelCaptura;
  final bool puedeSerEje;
  final String ayuda;
  final String ejemplo;

  @override
  List<Object?> get props => [
    nombre,
    tipo,
    esVariante,
    id,
    clave,
    requerido,
    opciones,
    unidades,
    unidadPredeterminada,
    minimo,
    maximo,
    decimales,
    maximoSelecciones,
    magnitud,
    nivelCaptura,
    puedeSerEje,
    ayuda,
    ejemplo,
  ];
}
