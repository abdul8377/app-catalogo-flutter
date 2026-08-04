import 'package:equatable/equatable.dart';

import 'atributo_def.dart';

export 'atributo_def.dart';
export 'precio_producto.dart';
export 'presentacion_producto.dart';

class CatalogoFormData extends Equatable {
  const CatalogoFormData({
    required this.empresas,
    required this.marcas,
    required this.subcategorias,
    required this.atributos,
    this.marcasPorEmpresa = const {},
    this.categoriasPorMarca = const {},
  });
  final List<String> empresas;
  final List<String> marcas;
  final Map<String, List<String>> subcategorias;
  final Map<String, List<AtributoDef>> atributos;
  final Map<String, List<String>> marcasPorEmpresa;
  final Map<String, List<String>> categoriasPorMarca;
  List<String> get categorias => subcategorias.keys.toList();

  List<String> marcasDe(String? empresa) =>
      empresa == null ? const [] : marcasPorEmpresa[empresa] ?? const [];

  List<String> categoriasDe(String? empresa, String? marca) {
    if (empresa == null || marca == null) return const [];
    return categoriasPorMarca['$empresa::$marca'] ?? const [];
  }

  @override
  List<Object?> get props => [
    empresas,
    marcas,
    subcategorias,
    atributos,
    marcasPorEmpresa,
    categoriasPorMarca,
  ];
}
