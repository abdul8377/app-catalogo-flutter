import 'package:equatable/equatable.dart';

class PresentacionProducto extends Equatable {
  const PresentacionProducto({required this.nombre, required this.unidad});

  final String nombre;
  final String unidad;

  Map<String, dynamic> toMap() => {'nombre': nombre, 'unidad': unidad};

  @override
  List<Object?> get props => [nombre, unidad];
}
