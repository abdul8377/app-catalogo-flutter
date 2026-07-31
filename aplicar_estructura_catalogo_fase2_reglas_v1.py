from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

ENTITY_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/domain/entities/"
    / "estructura_catalogo.dart"
)
DATASOURCE_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/data/datasources/"
    / "estructura_catalogo_local_datasource.dart"
)
INTEGRATED_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/pages/"
    / "estructura_catalogo_integrada.dart"
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


for path in (ENTITY_PATH, DATASOURCE_PATH, INTEGRATED_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

entity = ENTITY_PATH.read_text(encoding="utf-8")
datasource = DATASOURCE_PATH.read_text(encoding="utf-8")
integrated = INTEGRATED_PATH.read_text(encoding="utf-8")

if "class RelacionMarcaCategoria" not in entity:
    fail("No se encontró la entidad de relaciones.")
if "_guardarRelacionesTxn" not in datasource:
    fail("No se encontró la persistencia de relaciones.")

entity = replace_once(
    entity,
    '''class RelacionMarcaCategoria extends Equatable {
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
''',
    '''class RelacionMarcaCategoria extends Equatable {
  const RelacionMarcaCategoria({
    required this.marcaId,
    required this.categoriaId,
    required this.activa,
    this.productosActivos = 0,
  });

  final int marcaId;
  final int categoriaId;
  final bool activa;

  /// Productos activos que usan exactamente esta empresa, marca y
  /// categoría principal. Es la cantidad que bloquea una desvinculación.
  final int productosActivos;

  @override
  List<Object?> get props => [
    marcaId,
    categoriaId,
    activa,
    productosActivos,
  ];
}
''',
    "uso exacto en la entidad de relación",
)

datasource = replace_once(
    datasource,
    "      db.query('marca_categorias'),\n",
    """      db.rawQuery('''
        SELECT mc.marca_id,
               mc.categoria_id,
               mc.estado,
               (
                 SELECT COUNT(*)
                 FROM productos p
                 INNER JOIN marcas relacion_marca
                   ON relacion_marca.id = mc.marca_id
                 INNER JOIN empresas relacion_empresa
                   ON relacion_empresa.id = relacion_marca.empresa_id
                 INNER JOIN categorias relacion_categoria
                   ON relacion_categoria.id = mc.categoria_id
                 WHERE p.activo = 1
                   AND LOWER(TRIM(p.empresa)) =
                       LOWER(TRIM(relacion_empresa.nombre))
                   AND LOWER(TRIM(p.marca)) =
                       LOWER(TRIM(relacion_marca.nombre))
                   AND LOWER(TRIM(p.categoria)) =
                       LOWER(TRIM(relacion_categoria.nombre))
               ) AS productos_activos
        FROM marca_categorias mc
        ORDER BY mc.marca_id, mc.categoria_id
      '''),
""",
    "consulta exacta de uso por relación",
)

datasource = replace_once(
    datasource,
    '''            (row) => RelacionMarcaCategoria(
              marcaId: row['marca_id'] as int,
              categoriaId: row['categoria_id'] as int,
              activa: (row['estado'] as int? ?? 1) == 1,
            ),
''',
    '''            (row) => RelacionMarcaCategoria(
              marcaId: row['marca_id'] as int,
              categoriaId: row['categoria_id'] as int,
              activa: (row['estado'] as int? ?? 1) == 1,
              productosActivos:
                  row['productos_activos'] as int? ?? 0,
            ),
''',
    "mapear uso exacto de relación",
)

integrated = replace_once(
    integrated,
    '''          activeProductCount: snapshot.categorias
              .where((category) => category.id == item.categoriaId)
              .fold(0, (total, category) => total + category.cantidadProductos),
''',
    "          activeProductCount: item.productosActivos,\n",
    "usar conteo exacto en el panel",
)

datasource = replace_once(
    datasource,
    '''        await txn.insert('marcas', {
          'empresa_id': entityId,
          'nombre': 'Sin marca',
          'estado': 1,
          'actualizado_en': now,
        });
''',
    "",
    "retirar creación oculta de Sin marca",
)

datasource = replace_once(
    datasource,
    '''          SELECT m.nombre, e.nombre AS empresa
          FROM marcas m
''',
    '''          SELECT m.nombre,
                 m.empresa_id,
                 e.nombre AS empresa
          FROM marcas m
''',
    "leer empresa anterior de la marca",
)

datasource = replace_once(
    datasource,
    """        if (previous.isEmpty) throw StateError('La marca ya no existe.');
        await txn.update(
          'marcas',
""",
    """        if (previous.isEmpty) throw StateError('La marca ya no existe.');
        final previousCompanyId = previous.first['empresa_id'] as int;
        if (previousCompanyId != marca.empresaId) {
          final productCount =
              Sqflite.firstIntValue(
                await txn.rawQuery(
                  '''
                  SELECT COUNT(*)
                  FROM productos
                  WHERE LOWER(TRIM(empresa)) =
                        LOWER(TRIM(?))
                    AND LOWER(TRIM(marca)) =
                        LOWER(TRIM(?))
                  ''',
                  [
                    previous.first['empresa'] as String,
                    previous.first['nombre'] as String,
                  ],
                ),
              ) ??
              0;
          if (productCount > 0) {
            throw StateError(
              'La empresa propietaria no puede cambiarse porque la marca '
              'tiene $productCount producto(s). Utiliza un proceso de '
              'migración administrativa.',
            );
          }
        }
        await txn.update(
          'marcas',
""",
    "bloquear traslado de marca utilizada",
)

datasource = replace_once(
    datasource,
    '''        throw StateError(
          'Solo se pueden relacionar categorías principales activas.',
        );
''',
    '''        throw StateError(
          'La marca solo puede relacionarse con categorías principales '
          'activas. Las subcategorías se habilitan automáticamente.',
        );
''',
    "mensaje coherente de relación principal",
)

updates = {
    ENTITY_PATH: entity,
    DATASOURCE_PATH: datasource,
    INTEGRATED_PATH: integrated,
}

for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado para {path.relative_to(ROOT)} quedó vacío.")

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_estructura_catalogo_fase2_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nFase 2 de reglas de negocio aplicada.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
