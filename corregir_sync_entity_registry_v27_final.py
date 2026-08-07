from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil
import sys

ROOT = Path.cwd()
REGISTRY_REL = Path(
    "lib/features/sync/data/mappers/sync_entity_registry.dart"
)
APP_DATABASE_REL = Path("lib/core/database/app_database.dart")
MIGRATION_REL = Path(
    "lib/core/database/migrations/"
    "measurement_unit_sync_identity_migration.dart"
)


def app_root() -> Path:
    for candidate in (ROOT / "app_catalogo", ROOT):
        if (
            (candidate / REGISTRY_REL).exists()
            and (candidate / APP_DATABASE_REL).exists()
            and (candidate / "pubspec.yaml").exists()
        ):
            return candidate
    raise SystemExit(
        "No se encontró la app Flutter. Ejecuta este script desde "
        "D:\\AndroidStudioProyects\\app_catalogo o desde la raíz "
        "del repositorio que contiene app_catalogo."
    )


APP = app_root()
REGISTRY = APP / REGISTRY_REL
APP_DATABASE = APP / APP_DATABASE_REL
MIGRATION = APP / MIGRATION_REL
BACKUP_ROOT = (
    APP / ".correction_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
)

IDENTITY_BLOCK = """    if (spec.identityColumn == 'sync_id') {
      values['sync_id'] = entityId;
      values.remove('id');
    } else {
      values['id'] = entityId;
    }
"""

SPECIAL_IDENTITY_BLOCK = """    if (entityType == 'MEASUREMENT_UNIT') {
      await _applyRemoteMeasurementUnit(
        database,
        entityId: entityId,
        values: values,
      );
      return;
    }

""" + IDENTITY_BLOCK

MEASUREMENT_SPEC_OLD = """  'MEASUREMENT_UNIT': _SyncEntitySpec(table: 'unidades_medida'),
"""

MEASUREMENT_SPEC_NEW = """  'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
  ),
"""

CATEGORY_ATTRIBUTE_UNIT_OLD = """  'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
  ),
"""

CATEGORY_ATTRIBUTE_UNIT_NEW = """  'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
    integerReferences: {'unidad_medida_id': 'unidades_medida'},
  ),
"""

MEASUREMENT_HELPER = """  Future<void> _applyRemoteMeasurementUnit(
    DatabaseExecutor database, {
    required String entityId,
    required Map<String, Object?> values,
  }) async {
    final unitValues = Map<String, Object?>.from(values)
      ..remove('id')
      ..['sync_id'] = entityId;

    final remoteMatches = await database.query(
      'unidades_medida',
      columns: const ['id'],
      where: 'sync_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    if (remoteMatches.isNotEmpty) {
      await database.update(
        'unidades_medida',
        unitValues,
        where: 'id = ?',
        whereArgs: [remoteMatches.single['id']],
      );
      return;
    }

    final code = unitValues['codigo']?.toString().trim() ?? '';
    if (code.isNotEmpty) {
      final naturalMatches = await database.query(
        'unidades_medida',
        columns: const ['id', 'sync_id'],
        where: 'codigo = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (naturalMatches.isNotEmpty) {
        final naturalMatch = naturalMatches.single;
        final currentSyncId =
            naturalMatch['sync_id']?.toString().trim() ?? '';
        if (currentSyncId.isNotEmpty && currentSyncId != entityId) {
          throw StateError(
            'La unidad $code ya está vinculada con $currentSyncId '
            'y no puede vincularse con $entityId.',
          );
        }
        await database.update(
          'unidades_medida',
          unitValues,
          where: 'id = ?',
          whereArgs: [naturalMatch['id']],
        );
        return;
      }
    }

    unitValues['id'] = entityId;
    await database.insert('unidades_medida', unitValues);
  }

"""


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"No se encontró el archivo: {path}")
    return path.read_text(encoding="utf-8")


def backup(path: Path) -> None:
    destination = BACKUP_ROOT / path.relative_to(APP)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)


def replace_exact(
    content: str,
    old: str,
    new: str,
    label: str,
    already_marker: str,
) -> str:
    if already_marker in content:
        print(f"Ya aplicada: {label}")
        return content
    count = content.count(old)
    if count != 1:
        raise SystemExit(
            f"No se pudo aplicar '{label}'. "
            f"Se esperaba 1 coincidencia exacta y se encontraron {count}."
        )
    print(f"Aplicada: {label}")
    return content.replace(old, new, 1)


def verify_v27() -> None:
    database_content = read(APP_DATABASE)
    version_match = re.search(
        r"static\s+const\s+version\s*=\s*(\d+)\s*;",
        database_content,
    )
    if not version_match or int(version_match.group(1)) < 27:
        raise SystemExit(
            "app_database.dart no está en SQLite V27 o superior."
        )
    if (
        "measurement_unit_sync_identity_migration.dart"
        not in database_content
        or "_migrarIdentidadSincronizacionUnidadesV27"
        not in database_content
    ):
        raise SystemExit(
            "app_database.dart no registra correctamente la migración V27."
        )
    migration_content = read(MIGRATION)
    for fragment in (
        "ALTER TABLE unidades_medida ADD COLUMN sync_id TEXT",
        "uq_unidades_medida_sync_id",
    ):
        if fragment not in migration_content:
            raise SystemExit(
                "La migración V27 existe, pero su contenido no es el esperado."
            )
    print("SQLite V27 verificado correctamente.")


def patch_registry_content(content: str) -> str:
    if "naturalKeyColumn" in content or "copyRemoteIdToLocalId" in content:
        raise SystemExit(
            "Se encontró una aplicación parcial del primer enfoque "
            "(naturalKeyColumn/copyRemoteIdToLocalId). Restaura únicamente "
            "sync_entity_registry.dart desde la copia de seguridad anterior "
            "y vuelve a ejecutar este archivo."
        )

    content = replace_exact(
        content,
        IDENTITY_BLOCK,
        SPECIAL_IDENTITY_BLOCK,
        "interceptar MEASUREMENT_UNIT antes del insert genérico",
        "await _applyRemoteMeasurementUnit(",
    )

    if "Future<void> _applyRemoteMeasurementUnit(" not in content:
        sqlite_method = re.search(
            r"(?m)^  Object\?\s+_sqliteValue\s*\(",
            content,
        )
        if not sqlite_method:
            raise SystemExit(
                "No se encontró el método _sqliteValue para insertar "
                "el resolvedor de unidades."
            )
        content = (
            content[:sqlite_method.start()]
            + MEASUREMENT_HELPER
            + content[sqlite_method.start():]
        )
        print("Aplicada: agregar resolvedor de unidades por sync_id/codigo")
    else:
        print("Ya aplicada: resolvedor de unidades")

    content = replace_exact(
        content,
        MEASUREMENT_SPEC_OLD,
        MEASUREMENT_SPEC_NEW,
        "usar sync_id como identidad de MEASUREMENT_UNIT",
        """  'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
""",
    )

    content = replace_exact(
        content,
        CATEGORY_ATTRIBUTE_UNIT_OLD,
        CATEGORY_ATTRIBUTE_UNIT_NEW,
        "traducir unidad_medida_id a la PK local",
        "integerReferences: {'unidad_medida_id': 'unidades_medida'}",
    )

    required_fragments = (
        "await _applyRemoteMeasurementUnit(",
        "Future<void> _applyRemoteMeasurementUnit(",
        """'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
""",
        "integerReferences: {'unidad_medida_id': 'unidades_medida'}",
    )
    missing = [
        fragment for fragment in required_fragments if fragment not in content
    ]
    if missing:
        raise SystemExit(
            "La validación final falló. Fragmentos ausentes: "
            + ", ".join(missing)
        )
    return content


def patch_registry() -> None:
    original = read(REGISTRY)
    content = patch_registry_content(original)
    if content == original:
        print("sync_entity_registry.dart ya estaba completamente corregido.")
        return

    backup(REGISTRY)
    REGISTRY.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {REGISTRY.relative_to(APP)}")
    print(f"Copia: {(BACKUP_ROOT / REGISTRY.relative_to(APP)).relative_to(APP)}")


def main() -> None:
    print(f"App detectada: {APP}")
    print(f"Copias de seguridad: {BACKUP_ROOT.relative_to(APP)}")
    verify_v27()
    patch_registry()

    print("\nCorrección final V27 aplicada.")
    print("\nEjecuta:")
    print(
        "  dart format "
        "lib/features/sync/data/mappers/sync_entity_registry.dart"
    )
    print("  flutter clean")
    print("  flutter pub get")
    print("  flutter analyze")
    print("  flutter test")
    print("  flutter build apk --debug")
    print("\nDespués instala el APK y usa:")
    print("  Reconstruir datos de la PC")


if __name__ == "__main__":
    try:
        main()
    except Exception as exception:
        print(f"\nERROR: {exception}", file=sys.stderr)
        raise
