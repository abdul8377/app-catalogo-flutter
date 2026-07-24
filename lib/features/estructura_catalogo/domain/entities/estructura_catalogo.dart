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
  });

  final List<EmpresaCatalogo> empresas;
  final List<MarcaCatalogo> marcas;
  final List<CategoriaCatalogo> categorias;
  final List<RelacionMarcaCategoria> relaciones;

  @override
  List<Object?> get props => [empresas, marcas, categorias, relaciones];
}

class EmpresaCatalogoDraft extends Equatable {
  const EmpresaCatalogoDraft({
    required this.nombre,
    this.ruc = '',
    this.telefono = '',
    this.direccion = '',
  });

  final String nombre;
  final String ruc;
  final String telefono;
  final String direccion;

  @override
  List<Object?> get props => [nombre, ruc, telefono, direccion];
}

class MarcaCatalogoDraft extends Equatable {
  const MarcaCatalogoDraft({
    required this.empresaId,
    required this.nombre,
    this.categoriaIds = const {},
  });

  final int empresaId;
  final String nombre;
  final Set<int> categoriaIds;

  @override
  List<Object?> get props => [empresaId, nombre, categoriaIds];
}

class CategoriaCatalogoDraft extends Equatable {
  const CategoriaCatalogoDraft({
    required this.nombre,
    this.descripcion = '',
    this.categoriaPadreId,
  });

  final String nombre;
  final String descripcion;
  final int? categoriaPadreId;

  @override
  List<Object?> get props => [nombre, descripcion, categoriaPadreId];
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
