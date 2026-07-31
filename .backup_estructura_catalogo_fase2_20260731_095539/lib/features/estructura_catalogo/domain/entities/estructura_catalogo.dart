import 'package:equatable/equatable.dart';

class EmpresaCatalogo extends Equatable {
  const EmpresaCatalogo({
    required this.id,
    required this.nombre,
    required this.ruc,
    required this.telefono,
    required this.direccion,
    required this.activa,
    required this.cantidadMarcas,
    required this.cantidadCategorias,
    required this.cantidadProductos,
    required this.principalesMarcas,
  });

  final int id;
  final String nombre;
  final String ruc;
  final String telefono;
  final String direccion;
  final bool activa;
  final int cantidadMarcas;
  final int cantidadCategorias;
  final int cantidadProductos;
  final List<String> principalesMarcas;

  @override
  List<Object?> get props => [
    id,
    nombre,
    ruc,
    telefono,
    direccion,
    activa,
    cantidadMarcas,
    cantidadCategorias,
    cantidadProductos,
    principalesMarcas,
  ];
}

class MarcaCatalogo extends Equatable {
  const MarcaCatalogo({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.empresaNombre,
    required this.activa,
    required this.categorias,
    required this.cantidadProductos,
  });

  final int id;
  final int empresaId;
  final String nombre;
  final String empresaNombre;
  final bool activa;
  final List<String> categorias;
  final int cantidadProductos;

  @override
  List<Object?> get props => [
    id,
    empresaId,
    nombre,
    empresaNombre,
    activa,
    categorias,
    cantidadProductos,
  ];
}

class CategoriaCatalogo extends Equatable {
  const CategoriaCatalogo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activa,
    required this.marcas,
    required this.empresas,
    required this.cantidadProductos,
    this.categoriaPadreId,
    this.categoriaPadreNombre,
  });

  final int id;
  final int? categoriaPadreId;
  final String? categoriaPadreNombre;
  final String nombre;
  final String descripcion;
  final bool activa;
  final List<String> marcas;
  final List<String> empresas;
  final int cantidadProductos;

  bool get esRaiz => categoriaPadreId == null;

  @override
  List<Object?> get props => [
    id,
    categoriaPadreId,
    categoriaPadreNombre,
    nombre,
    descripcion,
    activa,
    marcas,
    empresas,
    cantidadProductos,
  ];
}

class RelacionMarcaCategoria extends Equatable {
  const RelacionMarcaCategoria({
    required this.marcaId,
    required this.categoriaId,
    required this.activa,
  });

  final int marcaId;
  final int categoriaId;
  final bool activa;

  @override
  List<Object?> get props => [marcaId, categoriaId, activa];
}

class EstructuraCatalogoSnapshot extends Equatable {
  const EstructuraCatalogoSnapshot({
    required this.empresas,
    required this.marcas,
    required this.categorias,
    required this.relaciones,
    this.atributos = const [],
    this.unidades = const [],
  });

  final List<EmpresaCatalogo> empresas;
  final List<MarcaCatalogo> marcas;
  final List<CategoriaCatalogo> categorias;
  final List<RelacionMarcaCategoria> relaciones;
  final List<AtributoCategoriaCatalogo> atributos;
  final List<UnidadMedidaCatalogo> unidades;

  @override
  List<Object?> get props => [
    empresas,
    marcas,
    categorias,
    relaciones,
    atributos,
    unidades,
  ];
}

class EmpresaCatalogoDraft extends Equatable {
  const EmpresaCatalogoDraft({
    required this.nombre,
    this.ruc = '',
    this.telefono = '',
    this.direccion = '',
    this.activa = true,
  });

  final String nombre;
  final String ruc;
  final String telefono;
  final String direccion;
  final bool activa;

  @override
  List<Object?> get props => [nombre, ruc, telefono, direccion, activa];
}

class MarcaCatalogoDraft extends Equatable {
  const MarcaCatalogoDraft({
    required this.empresaId,
    required this.nombre,
    this.categoriaIds = const {},
    this.activa = true,
  });

  final int empresaId;
  final String nombre;
  final Set<int> categoriaIds;
  final bool activa;

  @override
  List<Object?> get props => [empresaId, nombre, categoriaIds, activa];
}

class CategoriaCatalogoDraft extends Equatable {
  const CategoriaCatalogoDraft({
    required this.nombre,
    this.descripcion = '',
    this.categoriaPadreId,
    this.activa = true,
  });

  final String nombre;
  final String descripcion;
  final int? categoriaPadreId;
  final bool activa;

  @override
  List<Object?> get props => [nombre, descripcion, categoriaPadreId, activa];
}

class UnidadMedidaCatalogo extends Equatable {
  const UnidadMedidaCatalogo({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.simbolo,
    required this.magnitud,
    required this.factorBase,
    this.decimales = 3,
    this.activa = true,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String simbolo;
  final String magnitud;
  final double factorBase;
  final int decimales;
  final bool activa;

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    simbolo,
    magnitud,
    factorBase,
    decimales,
    activa,
  ];
}

class OpcionAtributoCategoriaCatalogo extends Equatable {
  const OpcionAtributoCategoriaCatalogo({
    required this.id,
    required this.etiqueta,
    required this.codigo,
    required this.activa,
    this.orden = 0,
    this.usadaPorProductos = 0,
  });

  final String id;
  final String etiqueta;
  final String codigo;
  final bool activa;
  final int orden;
  final int usadaPorProductos;

  @override
  List<Object?> get props => [
    id,
    etiqueta,
    codigo,
    activa,
    orden,
    usadaPorProductos,
  ];
}

class AtributoCategoriaCatalogo extends Equatable {
  const AtributoCategoriaCatalogo({
    required this.id,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.nombre,
    required this.clave,
    required this.tipoDato,
    required this.nivelCaptura,
    required this.requeridoActivar,
    required this.visibleFicha,
    required this.filtrable,
    required this.puedeSerEje,
    required this.activoNuevos,
    required this.orden,
    required this.activo,
    this.ayuda,
    this.longitudMaxima,
    this.ejemplo,
    this.minimo,
    this.maximo,
    this.decimales = 0,
    this.magnitud,
    this.codigosUnidad = const [],
    this.unidadPredeterminada,
    this.opciones = const [],
    this.maximoSelecciones,
    this.etiquetaVerdadero,
    this.etiquetaFalso,
    this.usadoPorProductos = 0,
    this.categoriasAfectadas = 0,
    this.usadoComoEje = 0,
    this.sincronizacionPendiente = false,
  });

  final String id;
  final int categoriaId;
  final String categoriaNombre;
  final String nombre;
  final String clave;
  final String? ayuda;
  final String tipoDato;
  final String nivelCaptura;
  final bool requeridoActivar;
  final bool visibleFicha;
  final bool filtrable;
  final bool puedeSerEje;
  final bool activoNuevos;
  final int orden;
  final bool activo;
  final int? longitudMaxima;
  final String? ejemplo;
  final double? minimo;
  final double? maximo;
  final int decimales;
  final String? magnitud;
  final List<String> codigosUnidad;
  final String? unidadPredeterminada;
  final List<OpcionAtributoCategoriaCatalogo> opciones;
  final int? maximoSelecciones;
  final String? etiquetaVerdadero;
  final String? etiquetaFalso;
  final int usadoPorProductos;
  final int categoriasAfectadas;
  final int usadoComoEje;
  final bool sincronizacionPendiente;

  @override
  List<Object?> get props => [
    id,
    categoriaId,
    categoriaNombre,
    nombre,
    clave,
    ayuda,
    tipoDato,
    nivelCaptura,
    requeridoActivar,
    visibleFicha,
    filtrable,
    puedeSerEje,
    activoNuevos,
    orden,
    activo,
    longitudMaxima,
    ejemplo,
    minimo,
    maximo,
    decimales,
    magnitud,
    codigosUnidad,
    unidadPredeterminada,
    opciones,
    maximoSelecciones,
    etiquetaVerdadero,
    etiquetaFalso,
    usadoPorProductos,
    categoriasAfectadas,
    usadoComoEje,
    sincronizacionPendiente,
  ];
}

class ImpactoEstructura extends Equatable {
  const ImpactoEstructura({
    required this.productos,
    required this.marcas,
    required this.categorias,
  });

  final int productos;
  final int marcas;
  final int categorias;

  bool get tieneImpacto => productos > 0 || marcas > 0 || categorias > 0;

  @override
  List<Object?> get props => [productos, marcas, categorias];
}
