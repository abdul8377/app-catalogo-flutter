from __future__ import annotations

from datetime import datetime
from pathlib import Path
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


def app_root() -> Path:
    candidates = (ROOT / "app_catalogo", ROOT)
    for candidate in candidates:
        if (
            (candidate / APP_DATABASE_REL).exists()
            and (candidate / REGISTRY_REL).exists()
            and (candidate / "pubspec.yaml").exists()
        ):
            return candidate
    raise SystemExit(
        "No se encontró la app Flutter. Ejecuta este script desde la raíz "
        "de app-catalogo-flutter o desde un repositorio combinado que "
        "contenga la carpeta app_catalogo."
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


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        raise SystemExit(
            f"No se pudo aplicar '{label}'. "
            f"Se esperaba 1 coincidencia y se encontraron {count}. "
            "El archivo puede haber cambiado."
        )
    return content.replace(old, new, 1)


def replace_unless_applied(
    content: str,
    old: str,
    new: str,
    marker: str,
    label: str,
) -> str:
    if marker in content:
        print(f"Ya aplicada: {label}")
        return content
    return replace_once(content, old, new, label)


def patch_database() -> None:
    content = read(APP_DATABASE)

    content = replace_unless_applied(
        content,
        "part 'migrations/technical_values_migrations.dart';\n",
        "part 'migrations/technical_values_migrations.dart';\n"
        "part 'migrations/measurement_unit_sync_identity_migration.dart';\n",
        "measurement_unit_sync_identity_migration.dart",
        "registrar migración V27",
    )

    if "static const version = 27;" not in content:
        content = replace_once(
            content,
            "static const version = 26;",
            "static const version = 27;",
            "incrementar SQLite a versión 27",
        )
    else:
        print("Ya aplicada: versión SQLite 27")

    content = replace_unless_applied(
        content,
        """          await _migrarListasPreciosV26(db);
        },
""",
        """          await _migrarListasPreciosV26(db);
          await _migrarIdentidadSincronizacionUnidadesV27(db);
        },
""",
        "await _migrarIdentidadSincronizacionUnidadesV27(db);\n        },",
        "ejecutar V27 al crear la base",
    )

    content = replace_unless_applied(
        content,
        """          if (oldVersion < 26) {
            await _migrarListasPreciosV26(db);
          }
        },
""",
        """          if (oldVersion < 26) {
            await _migrarListasPreciosV26(db);
          }
          if (oldVersion < 27) {
            await _migrarIdentidadSincronizacionUnidadesV27(db);
          }
        },
""",
        "if (oldVersion < 27)",
        "ejecutar V27 al actualizar la base",
    )

    backup(APP_DATABASE)
    write(APP_DATABASE, content)

    if MIGRATION.exists():
        current = read(MIGRATION).replace("\r\n", "\n").strip()
        expected = MIGRATION_SOURCE.strip()
        if current != expected:
            raise SystemExit(
                f"Ya existe {MIGRATION_REL} con otro contenido. "
                "No se sobrescribió."
            )
        print(f"Ya existe correctamente: {MIGRATION_REL}")
    else:
        write(MIGRATION, MIGRATION_SOURCE)


def patch_registry() -> None:
    content = read(REGISTRY)

    # 1. Soporte de clave natural en la especificación.
    content = replace_unless_applied(
        content,
        """  const _SyncEntitySpec({
    required this.table,
    this.identityColumn = 'id',
    this.integerReferences = const {},
  });

  final String table;
  final String identityColumn;
  final Map<String, String> integerReferences;
""",
        """  const _SyncEntitySpec({
    required this.table,
    this.identityColumn = 'id',
    this.integerReferences = const {},
    this.naturalKeyColumn,
    this.copyRemoteIdToLocalId = false,
  });

  final String table;
  final String identityColumn;
  final Map<String, String> integerReferences;
  final String? naturalKeyColumn;
  final bool copyRemoteIdToLocalId;
""",
        "final String? naturalKeyColumn;",
        "agregar identidad por clave natural",
    )

    # 2. Conservar ID local para tablas TEXT cuando se usa sync_id.
    content = replace_unless_applied(
        content,
        """    if (spec.identityColumn == 'sync_id') {
      values['sync_id'] = entityId;
      values.remove('id');
    } else {
      values['id'] = entityId;
    }
    final existing = await database.query(
""",
        """    if (spec.identityColumn == 'sync_id') {
      values['sync_id'] = entityId;
      if (spec.copyRemoteIdToLocalId) {
        values['id'] = entityId;
      } else {
        values.remove('id');
      }
    } else {
      values['id'] = entityId;
    }

    final naturalKeyColumn = spec.naturalKeyColumn;
    final naturalKeyValue = naturalKeyColumn == null
        ? null
        : values[naturalKeyColumn];
    if (naturalKeyColumn != null &&
        naturalKeyValue != null &&
        naturalKeyValue.toString().trim().isNotEmpty) {
      final naturalMatches = await database.query(
        spec.table,
        columns: ['id', spec.identityColumn],
        where: '$naturalKeyColumn = ?',
        whereArgs: [naturalKeyValue],
        limit: 1,
      );
      if (naturalMatches.isNotEmpty) {
        final naturalMatch = naturalMatches.single;
        final currentIdentity =
            naturalMatch[spec.identityColumn]?.toString() ?? '';
        if (currentIdentity.isEmpty || currentIdentity == entityId) {
          values['sync_id'] = entityId;
          values.remove('id');
          await database.update(
            spec.table,
            values,
            where: 'id = ?',
            whereArgs: [naturalMatch['id']],
          );
          return;
        }
        throw StateError(
          'La clave natural $naturalKeyColumn=$naturalKeyValue de '
          '$entityType ya pertenece a $currentIdentity.',
        );
      }
    }

    final existing = await database.query(
""",
        "final naturalKeyColumn = spec.naturalKeyColumn;",
        "fusionar maestros por clave natural",
    )

    # 3. Unidad maestra enlazada por sync_id y código.
    content = replace_unless_applied(
        content,
        """  'MEASUREMENT_UNIT': _SyncEntitySpec(table: 'unidades_medida'),
""",
        """  'MEASUREMENT_UNIT': _SyncEntitySpec(
    table: 'unidades_medida',
    identityColumn: 'sync_id',
    naturalKeyColumn: 'codigo',
    copyRemoteIdToLocalId: true,
  ),
""",
        "naturalKeyColumn: 'codigo'",
        "configurar identidad remota de unidades",
    )

    # 4. Resolver UUID remoto de unidad a PK local en la relación.
    content = replace_unless_applied(
        content,
        """  'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
  ),
""",
        """  'CATEGORY_ATTRIBUTE_UNIT': _SyncEntitySpec(
    table: 'categoria_atributo_unidades',
    integerReferences: {'unidad_medida_id': 'unidades_medida'},
  ),
""",
        "integerReferences: {'unidad_medida_id': 'unidades_medida'}",
        "resolver referencias atributo-unidad",
    )

    backup(REGISTRY)
    write(REGISTRY, content)


def main() -> None:
    print(f"App detectada: {APP}")
    print(f"Copias de seguridad: {BACKUP_ROOT.relative_to(APP)}")
    patch_database()
    patch_registry()

    print("\nCorrección de sincronización aplicada.")
    print("\nEjecuta desde la raíz de la app:")
    print("  flutter clean")
    print("  flutter pub get")
    print("  flutter analyze")
    print("  flutter test")
    print("  flutter build apk --debug")
    print("\nInstala el APK actualizado en la tablet y ejecuta:")
    print("  Reconstruir datos de la PC")
    print("\nNo es necesario modificar ni limpiar MySQL para esta corrección.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exception:
        print(f"\nERROR: {exception}", file=sys.stderr)
        raise
