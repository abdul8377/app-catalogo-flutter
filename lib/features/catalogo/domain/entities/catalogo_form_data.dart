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

class PresentacionProducto extends Equatable {
  const PresentacionProducto({required this.nombre, required this.unidad});
  final String nombre;
  final String unidad;
  Map<String, dynamic> toMap() => {'nombre': nombre, 'unidad': unidad};
  @override
  List<Object?> get props => [nombre, unidad];
}

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
