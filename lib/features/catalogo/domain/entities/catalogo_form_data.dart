import 'package:equatable/equatable.dart';

class AtributoDef extends Equatable {
  const AtributoDef({
    required this.nombre,
    required this.tipo,
    required this.esVariante,
  });
  final String nombre;
  final String tipo;
  final bool esVariante;
  @override
  List<Object?> get props => [nombre, tipo, esVariante];
}

class CatalogoFormData extends Equatable {
  const CatalogoFormData({
    required this.empresas,
    required this.marcas,
    required this.subcategorias,
    required this.atributos,
  });
  final List<String> empresas;
  final List<String> marcas;
  final Map<String, List<String>> subcategorias;
  final Map<String, List<AtributoDef>> atributos;
  List<String> get categorias => subcategorias.keys.toList();
  @override
  List<Object?> get props => [empresas, marcas, subcategorias, atributos];
}

class PresentacionProducto extends Equatable {
  const PresentacionProducto({required this.nombre, required this.unidad});
  final String nombre;
  final String unidad;
  Map<String, dynamic> toMap() => {'nombre': nombre, 'unidad': unidad};
  @override
  List<Object?> get props => [nombre, unidad];
}

class PrecioProducto extends Equatable {
  const PrecioProducto({required this.presentacion, required this.valor});
  final String presentacion;
  final double valor;
  Map<String, dynamic> toMap() => {
    'presentacion': presentacion,
    'valor': valor,
  };
  @override
  List<Object?> get props => [presentacion, valor];
}
