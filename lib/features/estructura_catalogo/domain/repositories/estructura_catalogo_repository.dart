import '../entities/estructura_catalogo.dart';

abstract class EstructuraCatalogoRepository {
  Future<EstructuraCatalogoSnapshot> obtenerEstructura();

  Future<void> guardarEmpresa({int? id, required EmpresaCatalogoDraft empresa});

  Future<void> guardarMarca({int? id, required MarcaCatalogoDraft marca});

  Future<void> guardarCategoria({
    int? id,
    required CategoriaCatalogoDraft categoria,
  });

  Future<void> guardarRelaciones({
    required int marcaId,
    required Set<int> categoriaIds,
  });

  Future<ImpactoEstructura> obtenerImpacto({
    required String tipo,
    required int id,
  });

  Future<void> cambiarEstado({
    required String tipo,
    required int id,
    required bool activo,
  });
}
