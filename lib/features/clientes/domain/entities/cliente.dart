import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.telefono,
    required this.activo,
    required this.pedidosCount,
    required this.fechaRegistro,
    this.dni,
    this.ruc,
    this.direccion,
    this.referencia,
    this.fotoUbicacionPath,
    this.ultimoPedido,
    this.observaciones,
    this.ultimaActualizacion,
  });

  final String id;
  final String nombre;
  final String tipo;
  final String telefono;
  final String? dni;
  final String? ruc;
  final String? direccion;
  final String? referencia;
  final String? fotoUbicacionPath;
  final bool activo;
  final int pedidosCount;
  final DateTime fechaRegistro;
  final DateTime? ultimoPedido;
  final String? observaciones;
  final DateTime? ultimaActualizacion;

  String get iniciales {
    final palabras = nombre.trim().split(RegExp(r'\s+'));
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return palabras.firstOrNull?.isNotEmpty == true
        ? palabras.first[0].toUpperCase()
        : '?';
  }

  Cliente copyWith({bool? activo}) => Cliente(
    id: id,
    nombre: nombre,
    tipo: tipo,
    telefono: telefono,
    dni: dni,
    ruc: ruc,
    direccion: direccion,
    referencia: referencia,
    fotoUbicacionPath: fotoUbicacionPath,
    activo: activo ?? this.activo,
    pedidosCount: pedidosCount,
    fechaRegistro: fechaRegistro,
    ultimoPedido: ultimoPedido,
    observaciones: observaciones,
    ultimaActualizacion: ultimaActualizacion,
  );

  @override
  List<Object?> get props => [
    id,
    nombre,
    tipo,
    telefono,
    dni,
    ruc,
    direccion,
    referencia,
    fotoUbicacionPath,
    activo,
    pedidosCount,
    fechaRegistro,
    ultimoPedido,
    observaciones,
    ultimaActualizacion,
  ];
}
