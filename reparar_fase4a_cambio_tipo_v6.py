from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

STATE_PATH = (
    ROOT
    / "lib/features/catalogo/presentation/bloc/producto_form_state.dart"
)
PAGE_PATH = (
    ROOT
    / "lib/features/catalogo/presentation/pages/producto_form_page.dart"
)
TEST_PATH = ROOT / "test/producto_form_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


for path in (STATE_PATH, PAGE_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path}")

state = STATE_PATH.read_text(encoding="utf-8")
page = PAGE_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

if "tieneConfiguracionDependiente" not in state:
    fail("No se encontró el estado aplicado por la fase 4A.")

if "Nombre de la familia *" not in page:
    fail("La fase 4A no parece estar aplicada en producto_form_page.dart.")

# ---------------------------------------------------------------------------
# 1. No considera la variante automática vacía como datos destructivos.
# ---------------------------------------------------------------------------

old_dependency = """  bool get tieneConfiguracionDependiente =>
      atributos.isNotEmpty ||
      variantes.isNotEmpty ||
      presentaciones.isNotEmpty ||
      ventaLogisticaContenido != null ||
      precios.isNotEmpty ||
      preciosConfigurados != null ||
      imagenesPaths.isNotEmpty ||
      imagenesConfiguradas != null;
"""

new_dependency = """  bool get tieneVariantesConDatosIngresados => variantes.any(
    (variant) =>
        variant.codigoProveedor.trim().isNotEmpty ||
        variant.nombreCorto.trim().isNotEmpty ||
        variant.atributos.isNotEmpty,
  );

  bool get tieneConfiguracionDependiente =>
      atributos.isNotEmpty ||
      tieneVariantesConDatosIngresados ||
      presentaciones.isNotEmpty ||
      ventaLogisticaContenido != null ||
      precios.isNotEmpty ||
      preciosConfigurados != null ||
      imagenesPaths.isNotEmpty ||
      imagenesConfiguradas != null;
"""

if old_dependency in state:
    state_updated = state.replace(old_dependency, new_dependency, 1)
elif "tieneVariantesConDatosIngresados" in state:
    state_updated = state
else:
    fail(
        "No se encontró el bloque esperado de configuración dependiente "
        "en ProductoFormState."
    )

# ---------------------------------------------------------------------------
# 2. Añade claves estables a los tres selectores de tipo.
# ---------------------------------------------------------------------------

method_start = page.find("  Widget _typeOption(")
if method_start < 0:
    fail("No se encontró el método _typeOption.")

method_end = page.find("\n  }\n}", method_start)
if method_end < 0:
    fail("No se pudo delimitar el método _typeOption.")

method_block = page[method_start:method_end]

if "key: Key('tipo_producto_$value')" not in method_block:
    marker = "    return InkWell(\n      onTap: () async {"
    if marker not in method_block:
        fail("No se encontró el InkWell del selector de tipo.")
    method_block = method_block.replace(
        marker,
        "    return InkWell(\n"
        "      key: Key('tipo_producto_$value'),\n"
        "      onTap: () async {",
        1,
    )

page_updated = page[:method_start] + method_block + page[method_end:]

# ---------------------------------------------------------------------------
# 3. Hace la prueba explícita y evita tocar un texto duplicado.
# ---------------------------------------------------------------------------

old_tap = "    await tester.tap(find.text('Lista de variantes'));"
new_tap = (
    "    await tester.tap("
    "find.byKey(const Key('tipo_producto_variantes'))"
    ");"
)

if old_tap in tests:
    tests_updated = tests.replace(old_tap, new_tap, 1)
elif "tipo_producto_variantes" in tests:
    tests_updated = tests
else:
    fail(
        "No se encontró la interacción de Lista de variantes en la prueba."
    )

# ---------------------------------------------------------------------------
# Respaldo y escritura.
# ---------------------------------------------------------------------------

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_reparacion_fase4a_tipo_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

updates = {
    STATE_PATH: state_updated,
    PAGE_PATH: page_updated,
    TEST_PATH: tests_updated,
}

for path in updates:
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nCambio de tipo corregido.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/flujo_producto_coherencia_test.dart")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
