from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys


ROOT = Path.cwd()

REGISTRY_REL = Path(
    "lib/features/sync/data/mappers/sync_entity_registry.dart"
)
LOCAL_DATASOURCE_REL = Path(
    "lib/features/sync/data/datasources/sync_local_datasource.dart"
)
REPOSITORY_REL = Path(
    "lib/features/sync/data/repositories/sync_repository_impl.dart"
)
DATABASE_REL = Path("lib/core/database/app_database.dart")
UNIT_MIGRATION_REL = Path(
    "lib/core/database/migrations/"
    "measurement_unit_sync_identity_migration.dart"
)


MERGE_CALL = """    if (await _mergeRemoteRelationalMasterByNaturalKey(
      database,
      entityType: entityType,
      entityId: entityId,
      values: values,
    )) {
      return;
    }

"""

MERGE_HELPER = """  Future<bool> _mergeRemoteRelationalMasterByNaturalKey(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required Map<String, Object?> values,
  }) async {
    if (!const {
      'COMPANY',
      'BRAND',
      'CATEGORY',
      'BRAND_CATEGORY',
    }.contains(entityType)) {
      return false;
    }

    final spec = _spec(entityType);
    final remoteMatches = await database.query(
      spec.table,
      columns: const ['sync_id'],
      where: 'sync_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    if (remoteMatches.isNotEmpty) {
      return false;
    }

    String where;
    List<Object?> whereArgs;
    switch (entityType) {
      case 'COMPANY':
        final name = values['nombre']?.toString().trim() ?? '';
        if (name.isEmpty) {
          return false;
        }
        where = 'nombre = ? COLLATE NOCASE';
        whereArgs = [name];
      case 'BRAND':
        final companyId = values['empresa_id'];
        final name = values['nombre']?.toString().trim() ?? '';
        if (companyId == null || name.isEmpty) {
          return false;
        }
        where = 'empresa_id = ? AND nombre = ? COLLATE NOCASE';
        whereArgs = [companyId, name];
      case 'CATEGORY':
        final parentId = values['categoria_padre_id'];
        final name = values['nombre']?.toString().trim() ?? '';
        if (name.isEmpty) {
          return false;
        }
        if (parentId == null) {
          where = 'categoria_padre_id IS NULL AND nombre = ? COLLATE NOCASE';
          whereArgs = [name];
        } else {
          where =
              'categoria_padre_id = ? AND nombre = ? COLLATE NOCASE';
          whereArgs = [parentId, name];
        }
      case 'BRAND_CATEGORY':
        final brandId = values['marca_id'];
        final categoryId = values['categoria_id'];
        if (brandId == null || categoryId == null) {
          return false;
        }
        where = 'marca_id = ? AND categoria_id = ?';
        whereArgs = [brandId, categoryId];
      default:
        return false;
    }

    final naturalMatches = await database.query(
      spec.table,
      columns: const ['sync_id'],
      where: where,
      whereArgs: whereArgs,
      limit: 2,
    );
    if (naturalMatches.isEmpty) {
      return false;
    }
    if (naturalMatches.length > 1) {
      throw StateError(
        'Se encontraron varias filas locales para la clave natural de '
        '$entityType.',
      );
    }

    final currentSyncId =
        naturalMatches.single['sync_id']?.toString().trim() ?? '';
    if (currentSyncId.isNotEmpty && currentSyncId != entityId) {
      final pending = await database.query(
        'sync_queue',
        columns: const ['id'],
        where:
            'entidad = ? AND entidad_id = ? '
            "AND estado IN ('pending', 'retry', 'sending', 'conflict')",
        whereArgs: [entityType, currentSyncId],
        limit: 1,
      );
      if (pending.isNotEmpty) {
        throw StateError(
          'No se puede adoptar la identidad remota de $entityType porque '
          'la fila local $currentSyncId tiene cambios pendientes.',
        );
      }
    }

    final mergedValues = Map<String, Object?>.from(values)
      ..remove('id')
      ..['sync_id'] = entityId;
    await database.update(
      spec.table,
      mergedValues,
      where: where,
      whereArgs: whereArgs,
    );
    return true;
  }

"""

CONTEXTUAL_APPLY = """    try {
      await _registry.applyRemote(
        transaction,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error) {
      throw StateError(
        'Error aplicando $entityType/$entityId '
        '($operation, version $version): $error',
      );
    }
"""

GENERIC_SYNC_CATCH = """    } catch (error) {
      throw SyncException(
        code: 'LOCAL_SYNC_APPLY_FAILED',
        message:
            'La tablet no pudo aplicar un registro recibido de la PC. '
            '$error',
      );
"""

FORMATTED_UNIT_MIGRATION = """part of '../app_database.dart';

extension _MeasurementUnitSyncIdentityMigration on AppDatabase {
  Future<void> _migrarIdentidadSincronizacionUnidadesV27(
    Database db,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'unidades_medida'",
    );
    if (tables.isEmpty) return;
    final columns = await db.rawQuery('PRAGMA table_info(unidades_medida)');
    final hasSyncId = columns.any((column) => column['name'] == 'sync_id');
    if (!hasSyncId) {
      await db.execute(
        'ALTER TABLE unidades_medida ADD COLUMN sync_id TEXT',
      );
    }

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'uq_unidades_medida_sync_id '
      'ON unidades_medida(sync_id) '
      'WHERE sync_id IS NOT NULL',
    );
  }
}
"""


def find_app_root() -> Path:
    for candidate in (ROOT / "app_catalogo", ROOT):
        if (
            (candidate / "pubspec.yaml").exists()
            and (candidate / REGISTRY_REL).exists()
            and (candidate / DATABASE_REL).exists()
        ):
            return candidate
    raise SystemExit(
        "No se encontró la app Flutter. Ejecuta el script desde la raíz "
        "de D:\\AndroidStudioProyects\\app_catalogo."
    )


APP = find_app_root()
REGISTRY = APP / REGISTRY_REL
LOCAL_DATASOURCE = APP / LOCAL_DATASOURCE_REL
REPOSITORY = APP / REPOSITORY_REL
DATABASE = APP / DATABASE_REL
UNIT_MIGRATION = APP / UNIT_MIGRATION_REL
BACKUP = APP / ".correction_backups" / datetime.now().strftime(
    "%Y%m%d_%H%M%S"
)


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"No existe: {path}")
    return path.read_text(encoding="utf-8")


def save(path: Path, content: str) -> None:
    relative = path.relative_to(APP)
    destination = BACKUP / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {relative}")
    print(f"  Copia: {destination.relative_to(APP)}")


def verify_unit_patch() -> None:
    database = read(DATABASE)
    version_match = re.search(
        r"static\s+const\s+version\s*=\s*(\d+)\s*;",
        database,
    )
    if not version_match or int(version_match.group(1)) < 27:
        raise SystemExit("SQLite debe estar en versión 27 o superior.")
    required_database = (
        "measurement_unit_sync_identity_migration.dart",
        "_migrarIdentidadSincronizacionUnidadesV27",
    )
    if not all(fragment in database for fragment in required_database):
        raise SystemExit(
            "app_database.dart no contiene completa la migración V27."
        )

    registry = read(REGISTRY)
    required_registry = (
        "Future<void> _applyRemoteMeasurementUnit(",
        "identityColumn: 'sync_id'",
        "integerReferences: {'unidad_medida_id': 'unidades_medida'}",
    )
    if not all(fragment in registry for fragment in required_registry):
        raise SystemExit(
            "sync_entity_registry.dart no contiene completa la corrección "
            "de unidades V27."
        )
    print("Corrección de unidades V27 verificada.")


def patch_registry() -> None:
    content = read(REGISTRY)
    original = content

    if "_mergeRemoteRelationalMasterByNaturalKey(" not in content:
        measurement_block = re.compile(
            r"(?P<block>"
            r"    if \(entityType == 'MEASUREMENT_UNIT'\) \{\n"
            r"      await _applyRemoteMeasurementUnit\(\n"
            r"        database,\n"
            r"        entityId: entityId,\n"
            r"        values: values,\n"
            r"      \);\n"
            r"      return;\n"
            r"    \}\n\n"
            r")"
        )
        match = measurement_block.search(content)
        if not match:
            raise SystemExit(
                "No se encontró el bloque MEASUREMENT_UNIT esperado."
            )
        content = (
            content[: match.end()]
            + MERGE_CALL
            + content[match.end() :]
        )

        helper_marker = "  Future<void> _applyRemoteMeasurementUnit("
        position = content.find(helper_marker)
        if position < 0:
            raise SystemExit(
                "No se encontró _applyRemoteMeasurementUnit para insertar "
                "el reconciliador."
            )
        content = (
            content[:position]
            + MERGE_HELPER
            + content[position:]
        )
        print(
            "Aplicado: reconciliación natural de empresa, marca, categoría "
            "y relación marca-categoría."
        )
    else:
        print("Ya existe el reconciliador de maestros relacionales.")

    if content != original:
        save(REGISTRY, content)


def patch_contextual_error() -> None:
    content = read(LOCAL_DATASOURCE)
    original = content

    old = """    await _registry.applyRemote(
      transaction,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
"""
    if "Error aplicando $entityType/$entityId" not in content:
        count = content.count(old)
        if count != 1:
            raise SystemExit(
                "No se pudo localizar exactamente la aplicación remota "
                f"en sync_local_datasource.dart; coincidencias: {count}."
            )
        content = content.replace(old, CONTEXTUAL_APPLY, 1)
        print("Aplicado: contexto de entidad al error de SQLite.")
    else:
        print("Ya existe el contexto de entidad en errores.")

    if content != original:
        save(LOCAL_DATASOURCE, content)


def patch_repository_error() -> None:
    content = read(REPOSITORY)
    original = content

    old = """    } on FormatException catch (error) {
      throw SyncException(
        code: 'INVALID_CONTRACT_JSON',
        message: error.message,
      );
    } finally {
"""
    new = """    } on FormatException catch (error) {
      throw SyncException(
        code: 'INVALID_CONTRACT_JSON',
        message: error.message,
      );
""" + GENERIC_SYNC_CATCH + """    } finally {
"""
    if "code: 'LOCAL_SYNC_APPLY_FAILED'" not in content:
        count = content.count(old)
        if count != 1:
            raise SystemExit(
                "No se pudo localizar el cierre de synchronize(); "
                f"coincidencias: {count}."
            )
        content = content.replace(old, new, 1)
        print("Aplicado: mensaje técnico controlado para fallos locales.")
    else:
        print("Ya existe LOCAL_SYNC_APPLY_FAILED.")

    if content != original:
        save(REPOSITORY, content)


def format_sources() -> None:
    # Se escribe primero la versión canónica para que incluso un entorno
    # sin Dart quede con el archivo que estaba rechazando GitHub.
    migration = read(UNIT_MIGRATION)
    if migration != FORMATTED_UNIT_MIGRATION:
        save(UNIT_MIGRATION, FORMATTED_UNIT_MIGRATION)

    dart = shutil.which("dart")
    if dart is None:
        raise SystemExit(
            "No se encontró 'dart' en PATH. Abre una terminal de Flutter "
            "y ejecuta: dart format lib test"
        )

    result = subprocess.run(
        [dart, "format", "lib", "test"],
        cwd=APP,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit("dart format terminó con error.")

    check = subprocess.run(
        [
            dart,
            "format",
            "--output=none",
            "--set-exit-if-changed",
            "lib",
            "test",
        ],
        cwd=APP,
        text=True,
    )
    if check.returncode != 0:
        raise SystemExit(
            "La verificación de formato sigue detectando cambios."
        )
    print("Formato CI verificado: OK.")


def run_command(command: list[str], label: str) -> None:
    print(f"\n== {label} ==")
    result = subprocess.run(command, cwd=APP)
    if result.returncode != 0:
        raise SystemExit(f"Falló: {' '.join(command)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Ejecuta analyze, pruebas estables y build debug.",
    )
    args = parser.parse_args()

    print(f"App detectada: {APP}")
    print(f"Copias de seguridad: {BACKUP.relative_to(APP)}")

    verify_unit_patch()
    patch_registry()
    patch_contextual_error()
    patch_repository_error()
    format_sources()

    print("\nCorrección aplicada.")
    print("\nRevisa y publica:")
    print("  git diff --check")
    print("  git status --short")
    print("  git diff")
    print("  git add lib")
    print(
        '  git commit -m "fix(sync): reconcile remote master identities"'
    )
    print("  git push origin main")

    if args.verify:
        flutter = shutil.which("flutter")
        dart = shutil.which("dart")
        if flutter is None or dart is None:
            raise SystemExit("No se encontró Flutter/Dart en PATH.")
        run_command([flutter, "pub", "get"], "Dependencias")
        run_command(
            [dart, "analyze", "--no-fatal-warnings"],
            "Análisis",
        )
        run_command(
            [
                flutter,
                "test",
                "--no-pub",
                "--exclude-tags",
                "baseline-known-failure",
            ],
            "Pruebas del mismo gate de CI",
        )
        run_command(
            [flutter, "build", "apk", "--debug", "--no-pub"],
            "APK debug",
        )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"\nERROR: {error}", file=sys.stderr)
        raise
