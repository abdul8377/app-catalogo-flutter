import 'package:equatable/equatable.dart';

class PrecioProducto extends Equatable {
  const PrecioProducto({
    required this.presentacion,
    required this.valor,
    this.listaPrecioId = '',
    this.varianteId = '',
    this.presentacionId = '',
    this.configuracion = 'precio_fijo',
  });

  final String presentacion;
  final double valor;
  final String listaPrecioId;
  final String varianteId;
  final String presentacionId;
  final String configuracion;

  Map<String, dynamic> toMap() => {
    'presentacion': presentacion,
    'valor': valor,
    'lista_precio_id': listaPrecioId,
    'variante_id': varianteId,
    'presentacion_id': presentacionId,
    'configuracion': configuracion,
  };

  @override
  List<Object?> get props => [
    presentacion,
    valor,
    listaPrecioId,
    varianteId,
    presentacionId,
    configuracion,
  ];
}
