import '../../domain/entities/estructura_catalogo.dart';
import '../../domain/repositories/estructura_catalogo_repository.dart';
import '../datasources/estructura_catalogo_local_datasource.dart';

class EstructuraCatalogoRepositoryImpl implements EstructuraCatalogoRepository {
  const EstructuraCatalogoRepositoryImpl(this.localDatasource);

  final EstructuraCatalogoLocalDatasource localDatasource;

  @override
  Future<EstructuraCatalogoSnapshot> obtenerEstructura() =>
      localDatasource.obtenerEstructura();

  @override
  Future<void> guardarEmpresa({
    int? id,
    required EmpresaCatalogoDraft empresa,
  }) => localDatasource.guardarEmpresa(id: id, empresa: empresa);

  @override
  Future<void> guardarMarca({int? id, required MarcaCatalogoDraft marca}) =>
      localDatasource.guardarMarca(id: id, marca: marca);

  @override
  Future<void> guardarCategoria({
    int? id,
    required CategoriaCatalogoDraft categoria,
  }) => localDatasource.guardarCategoria(id: id, categoria: categoria);

  @override
  Future<void> guardarRelaciones({
    required int marcaId,
    required Set<int> categoriaIds,
  }) => localDatasource.guardarRelaciones(
    marcaId: marcaId,
    categoriaIds: categoriaIds,
  );

  @override
  Future<void> guardarAtributosCategoria({
    required int categoriaId,
    required List<AtributoCategoriaCatalogo> atributos,
  }) => localDatasource.guardarAtributosCategoria(
    categoriaId: categoriaId,
    atributos: atributos,
  );

  @override
  Future<ImpactoEstructura> obtenerImpacto({
    required String tipo,
    required int id,
  }) => localDatasource.obtenerImpacto(tipo: tipo, id: id);

  @override
  Future<void> cambiarEstado({
    required String tipo,
    required int id,
    required bool activo,
  }) => localDatasource.cambiarEstado(tipo: tipo, id: id, activo: activo);
}
