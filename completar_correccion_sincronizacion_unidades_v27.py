from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil
import sys

ROOT = Path.cwd()

APP_DATABASE_REL = Path("lib/core/database/app_database.dart")
REGISTRY_REL = Path(
    "lib/features/sync/data/mappers/sync_entity_registry.dart"
)
MIGRATION_REL = Path(
    "lib/core/database/migrations/"
    "measurement_unit_sync_identity_migration.dart"
)

MIGRATION_SOURCE = """part of '../app_database.dart';

extension _MeasurementUnitSyncIdentityMigration on AppDatabase {
  Future<void> _migrarIdentidadSincronizacionUnidadesV27(
    Database db,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'unidades_medida'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery(
      'PRAGMA table_info(unidades_medida)',
    );
    final hasSyncId = columns.any(
      (column) => column['name'] == 'sync_id',
    );
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

MEASUREMENT_HELPER = "\n  Future<void> _applyRemoteMeasurementUnit(\n    DatabaseExecutor database, {\n    required String entityId,\n    required Map<String, Object?> values,\n  }) async {\n    final unitValues = Map<String, Object?>.from(values)\n      ..remove('id')\n      ..['sync_id'] = entityId;\n\n    final remoteMatches = await database.query(\n      'unidades_medida',\n      columns: const ['id'],\n      where: 'sync_id = ?',\n      whereArgs: [entityId],\n      limit: 1,\n    );\n    if (remoteMatches.isNotEmpty) {\n      await database.update(\n        'unidades_medida',\n        unitValues,\n        where: 'id = ?',\n        whereArgs: [remoteMatches.single['id']],\n      );\n      return;\n    }\n\n    final code = unitValues['codigo']?.toString().trim() ?? '';\n    if (code.isNotEmpty) {\n      final naturalMatches = await database.query(\n        'unidades_medida',\n        columns: const ['id', 'sync_id'],\n        where: 'codigo = ?',\n        whereArgs: [code],\n        limit: 1,\n      );\n      if (naturalMatches.isNotEmpty) {\n        final naturalMatch = naturalMatches.single;\n        final currentSyncId =\n            naturalMatch['sync_id']?.toString().trim() ?? '';\n        if (currentSyncId.isNotEmpty && currentSyncId != entityId) {\n          throw StateError(\n            'La unidad $code ya está vinculada con $currentSyncId '\n            'y no puede vincularse con $entityId.',\n          );\n        }\n        await database.update(\n          'unidades_medida',\n          unitValues,\n          where: 'id = ?',\n          whereArgs: [naturalMatch['id']],\n        );\n        return;\n      }\n    }\n\n    unitValues['id'] = entityId;\n    await database.insert('unidades_medida', unitValues);\n  }\n"


def app_root() -> Path:
    for candidate in (ROOT / "app_catalogo", ROOT):
        if (
            (candidate / APP_DATABASE_REL).exists()
            and (candidate / REGISTRY_REL).exists()
            and (candidate / "pubspec.yaml").exists()
        ):
            return candidate
    raise SystemExit(
        "No se encontró la app Flutter. Ejecuta este script desde la raíz "
        "de app-catalogo-flutter o desde la carpeta app_catalogo."
    )


APP = app_root()
APP_DATABASE = APP / APP_DATABASE_REL
REGISTRY = APP / REGISTRY_REL
MIGRATION = APP / MIGRATION_REL
BACKUP_ROOT = (
    APP / ".correction_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
)


def read(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"No se encontró el archivo: {path}")
    return path.read_text(encoding="utf-8")


def backup(path: Path) -> None:
    if not path.exists():
        return
    destination = BACKUP_ROOT / path.relative_to(APP)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(APP)}")


def ensure_database_v27() -> None:
    content = read(APP_DATABASE)
    original = content

    part_line = (
        "part 'migrations/"
        "measurement_unit_sync_identity_migration.dart';"
    )
    if part_line not in content:
        marker = "part 'migrations/technical_values_migrations.dart';"
        if marker not in content:
            raise SystemExit(
                "No se encontró el marcador de migraciones en "
                "app_database.dart."
            )
        content = content.replace(
            marker,
            marker + "\n" + part_line,
            1,
        )

    version_match = re.search(
        r"static\s+const\s+version\s*=\s*(\d+)\s*;",
        content,
    )
    if not version_match:
        raise SystemExit("No se encontró la versión SQLite.")
    version = int(version_match.group(1))
    if version < 27:
        content = (
            content[:version_match.start(1)]
            + "27"
            + content[version_match.end(1):]
        )
    elif version > 27:
        print(
            f"La base ya está en versión {version}; "
            "se conservará esa versión."
        )

    create_call = (
        "await _migrarIdentidadSincronizacionUnidadesV27(db);"
    )
    if create_call not in content:
        marker = "await _migrarListasPreciosV26(db);"
        first = content.find(marker)
        if first < 0:
            raise SystemExit(
                "No se encontró la llamada V26 en onCreate."
            )
        insertion = first + len(marker)
        content = (
            content[:insertion]
            + "\n          "
            + create_call
            + content[insertion:]
        )

    upgrade_block = re.compile(
        r"if\s*\(\s*oldVersion\s*<\s*27\s*\)\s*\{\s*"
        r"await\s+_migrarIdentidadSincronizacionUnidadesV27"
        r"\s*\(\s*db\s*\)\s*;\s*\}",
        re.DOTALL,
    )
    if not upgrade_block.search(content):
        v26_pattern = re.compile(
            r"(if\s*\(\s*oldVersion\s*<\s*26\s*\)\s*\{\s*"
            r"await\s+_migrarListasPreciosV26\s*"
            r"\(\s*db\s*\)\s*;\s*\})",
            re.DOTALL,
        )
        match = v26_pattern.search(content)
        if not match:
            raise SystemExit(
                "No se encontró el bloque de actualización V26."
            )
        addition = (
            match.group(1)
            + "\n          if (oldVersion < 27) {\n"
            + "            await "
            + "_migrarIdentidadSincronizacionUnidadesV27(db);\n"
            + "          }"
        )
        content = (
            content[:match.start()]
            + addition
            + content[match.end():]
        )

    if content != original:
        backup(APP_DATABASE)
        write(APP_DATABASE, content)
    else:
        print("app_database.dart ya contiene SQLite V27.")

    if not MIGRATION.exists():
        write(MIGRATION, MIGRATION_SOURCE)
    else:
        migration_content = read(MIGRATION)
        required_fragments = (
            "ALTER TABLE unidades_medida ADD COLUMN sync_id TEXT",
            "uq_unidades_medida_sync_id",
        )
        if not all(
            fragment in migration_content
            for fragment in required_fragments
        ):
            raise SystemExit(
                f"{MIGRATION_REL} existe, pero no contiene la "
                "migración V27 esperada."
            )
        print("La migración V27 ya existe correctamente.")


def patch_registry() -> None:
    content = read(REGISTRY)
    original = content

    if "naturalKeyColumn" in content or "copyRemoteIdToLocalId" in content:
        raise SystemExit(
            "sync_entity_registry.dart contiene una aplicación parcial "
            "del parche anterior. Restaura solo ese archivo desde la copia "
            "de seguridad más reciente y vuelve a ejecutar este script."
        )

    if "Future<void> _applyRemoteMeasurementUnit(" not in content:
        identity_pattern = re.compile(
            r"^(?P<indent>[ \t]*)if\s*"
            r"\(\s*spec\.identityColumn\s*==\s*'sync_id'\s*\)\s*\{",
            re.MULTILINE,
        )
        match = identity_pattern.search(content)
        if not match:
            raise SystemExit(
                "No se encontró el bloque identityColumn en "
                "sync_entity_registry.dart."
            )
        indent = match.group("indent")
        special_case = (
            f"{indent}if (entityType == 'MEASUREMENT_UNIT') {{\n"
            f"{indent}  await _applyRemoteMeasurementUnit(\n"
            f"{indent}    database,\n"
            f"{indent}    entityId: entityId,\n"
            f"{indent}    values: values,\n"
            f"{indent}  );\n"
            f"{indent}  return;\n"
            f"{indent}}}\n"
        )
        content = (
            content[:match.start()]
            + special_case
            + content[match.start():]
        )

        helper_marker = re.search(
            r"\n\s*Object\?\s+_sqliteValue\s*\(",
            content,
        )
        if not helper_marker:
            raise SystemExit(
                "No se encontró _sqliteValue para insertar el "
                "resolvedor de unidades."
            )
        content = (
            content[:helper_marker.start()]
            + "\n"
            + MEASUREMENT_HELPER.rstrip()
            + "\n"
            + content[helper_marker.start():]
        )
    else:
        print("El resolvedor especial de unidades ya está presente.")

    measurement_pattern = re.compile(
        r"'MEASUREMENT_UNIT'\s*:\s*_SyncEntitySpec\s*\("
        r"\s*table\s*:\s*'unidades_medida'\s*"
        r"(?:,\s*identityColumn\s*:\s*'[^']+'\s*)?"
        r"\)\s*,",
        re.DOTALL,
    )
    measurement_replacement = """'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
  ),"""
    if not re.search(
        r"'MEASUREMENT_UNIT'.*?identityColumn\s*:\s*'sync_id'",
        content,
        re.DOTALL,
    ):
        content, count = measurement_pattern.subn(
            measurement_replacement,
            content,
            count=1,
        )
        if count != 1:
            raise SystemExit(
                "No se pudo actualizar la especificación "
                "MEASUREMENT_UNIT."
            )

    unit_relation_pattern = re.compile(
        r"'CATEGORY_ATTRIBUTE_UNIT'\s*:\s*_SyncEntitySpec\s*\("
        r"\s*table\s*:\s*'categoria_atributo_unidades'\s*"
        r"(?:,\s*integerReferences\s*:\s*\{[^}]*\}\s*)?"
        r"\)\s*,",
        re.DOTALL,
    )
    unit_relation_replacement = """'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
    integerReferences: {'unidad_medida_id': 'unidades_medida'},
  ),"""
    if not re.search(
        r"'CATEGORY_ATTRIBUTE_UNIT'.*?"
        r"'unidad_medida_id'\s*:\s*'unidades_medida'",
        content,
        re.DOTALL,
    ):
        content, count = unit_relation_pattern.subn(
            unit_relation_replacement,
            content,
            count=1,
        )
        if count != 1:
            raise SystemExit(
                "No se pudo actualizar CATEGORY_ATTRIBUTE_UNIT."
            )

    required = (
        "Future<void> _applyRemoteMeasurementUnit(",
        "'MEASUREMENT_UNIT': _SyncEntitySpec(",
        "identityColumn: 'sync_id'",
        "'unidad_medida_id': 'unidades_medida'",
    )
    if not all(fragment in content for fragment in required):
        raise SystemExit(
            "La validación final de sync_entity_registry.dart falló."
        )

    if content != original:
        backup(REGISTRY)
        write(REGISTRY, content)
    else:
        print("sync_entity_registry.dart ya estaba corregido.")


def main() -> None:
    print(f"App detectada: {APP}")
    print(f"Copias de seguridad: {BACKUP_ROOT.relative_to(APP)}")

    ensure_database_v27()
    patch_registry()

    print("\nCorrección V27 completada.")
    print("\nEjecuta ahora:")
    print("  dart format lib/core/database/app_database.dart")
    print(
        "  dart format "
        "lib/core/database/migrations/"
        "measurement_unit_sync_identity_migration.dart"
    )
    print(
        "  dart format "
        "lib/features/sync/data/mappers/"
        "sync_entity_registry.dart"
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
