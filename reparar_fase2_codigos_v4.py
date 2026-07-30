from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

BLOC_PATH = (
    ROOT
    / "lib/features/catalogo/presentation/bloc/producto_form_bloc.dart"
)
TEST_PATH = ROOT / "test/producto_form_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


for path in (BLOC_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path}")

bloc = BLOC_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 1. Corrige la coma omitida en state.copyWith(...)
# ---------------------------------------------------------------------------

comma_pattern = re.compile(
    r"(?P<datos>datos\s*:\s*datos)"
    r"(?P<between>\s*\n\s*)"
    r"(?P<codigo>codigo\s*:\s*"
    r"CodigoInternoGenerator\.nuevoProducto\(\)\s*,)"
)

comma_match = comma_pattern.search(bloc)

if comma_match is not None:
    bloc_updated = (
        bloc[: comma_match.start()]
        + comma_match.group("datos")
        + ","
        + comma_match.group("between")
        + comma_match.group("codigo")
        + bloc[comma_match.end() :]
    )
elif re.search(
    r"datos\s*:\s*datos\s*,\s*\n\s*"
    r"codigo\s*:\s*CodigoInternoGenerator\.nuevoProducto\(\)\s*,",
    bloc,
):
    bloc_updated = bloc
else:
    fail(
        "No se encontró el bloque `datos: datos` seguido del código "
        "interno generado."
    )

# ---------------------------------------------------------------------------
# 2. Corrige la comprobación readOnly de la prueba.
# ---------------------------------------------------------------------------

old_assertion = "      expect(internalField.readOnly, isTrue);"

new_assertion = '''      final internalEditable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('variante_codigo_interno')),
          matching: find.byType(EditableText),
        ),
      );
      expect(internalEditable.readOnly, isTrue);'''

if old_assertion in tests:
    tests_updated = tests.replace(old_assertion, new_assertion, 1)
elif "expect(internalEditable.readOnly, isTrue);" in tests:
    tests_updated = tests
else:
    fail(
        "No se encontró la comprobación `internalField.readOnly` "
        "en la prueba."
    )

# ---------------------------------------------------------------------------
# Escritura con respaldo.
# ---------------------------------------------------------------------------

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_reparacion_fase2_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in (BLOC_PATH, TEST_PATH):
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

BLOC_PATH.write_text(bloc_updated, encoding="utf-8", newline="\n")
TEST_PATH.write_text(tests_updated, encoding="utf-8", newline="\n")

print(f"Modificado: {BLOC_PATH.relative_to(ROOT)}")
print(f"Modificado: {TEST_PATH.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nReparación aplicada.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
