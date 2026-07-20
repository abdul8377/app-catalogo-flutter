import 'package:equatable/equatable.dart';

class NuevoCliente extends Equatable {
  const NuevoCliente({
    required this.nombre,
    required this.tipo,
    required this.telefono,
    required this.direccion,
    required this.activo,
    this.dni = '',
    this.ruc = '',
    this.referencia = '',
    this.fotoUbicacionPath,
    this.observaciones = '',
  });

  final String nombre;
  final String tipo;
  final String telefono;
  final String dni;
  final String ruc;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final bool activo;
  final String observaciones;

  @override
  List<Object?> get props => [
    nombre,
    tipo,
    telefono,
    dni,
    ruc,
    direccion,
    referencia,
    fotoUbicacionPath,
    activo,
    observaciones,
  ];
}
