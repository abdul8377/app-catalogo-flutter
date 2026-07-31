from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

MANAGER_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/pages/"
    / "gestionar_atributos_categoria.dart"
)
TEST_PATH = ROOT / "test/estructura_catalogo_page_test.dart"


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


for path in (MANAGER_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

manager = MANAGER_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

required = (
    "DropdownButtonFormField<CategoryAttributeDataType>(",
    "DropdownButtonFormField<AttributeCaptureLevel>(",
    "find.text('Categoría temporal'), findsOneWidget",
)
missing = [marker for marker in required if marker not in manager + tests]
if missing:
    fail(
        "El código no corresponde al estado esperado después de la reparación "
        f"de estabilidad. Faltan: {', '.join(missing)}"
    )

manager = replace_once(
    manager,
    """                  DropdownButtonFormField<CategoryAttributeDataType>(
                    value: _type,
""",
    """                  DropdownButtonFormField<CategoryAttributeDataType>(
                    isExpanded: true,
                    value: _type,
""",
    "adaptar el selector de tipo de dato",
)

manager = replace_once(
    manager,
    """                            child: Text(_dataTypeLabel(type)),
""",
    """                            child: Text(
                              _dataTypeLabel(type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
""",
    "recortar de forma segura la etiqueta del tipo de dato",
)

manager = replace_once(
    manager,
    """                  DropdownButtonFormField<AttributeCaptureLevel>(
                    value: _captureLevel,
""",
    """                  DropdownButtonFormField<AttributeCaptureLevel>(
                    isExpanded: true,
                    value: _captureLevel,
""",
    "adaptar el selector de nivel de captura",
)

manager = replace_once(
    manager,
    """                            child: Text(_captureLevelLabel(level)),
""",
    """                            child: Text(
                              _captureLevelLabel(level),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
""",
    "recortar de forma segura la etiqueta del nivel de captura",
)

tests = replace_once(
    tests,
    """      expect(find.text('Categoría temporal'), findsOneWidget);
""",
    """      expect(find.text('Categoría temporal'), findsWidgets);
""",
    "ajustar la prueba a las apariciones válidas de la categoría",
)

updates = {
    MANAGER_PATH: manager,
    TEST_PATH: tests,
}

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_estructura_catalogo_overflow_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nDesplegables adaptables y prueba de categoría corregidos.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
