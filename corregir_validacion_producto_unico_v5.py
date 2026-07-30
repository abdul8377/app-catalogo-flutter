from pathlib import Path
import shutil
from datetime import datetime

root = Path.cwd()
test_path = root / "test/producto_form_page_test.dart"
state_path = root / "lib/features/catalogo/presentation/bloc/producto_form_state.dart"

for path in (test_path, state_path):
    if not path.exists():
        raise SystemExit(f"ERROR: no se encontró {path}")

test_text = test_path.read_text(encoding="utf-8")
state_text = state_path.read_text(encoding="utf-8")

old_test = "expect(find.text('Ingresa el nombre comercial.'), findsOneWidget);"
new_test = (
    "expect(\n"
    "        find.textContaining('Ingresa el nombre comercial'),\n"
    "        findsOneWidget,\n"
    "      );"
)

if old_test not in test_text and "find.textContaining('Ingresa el nombre comercial')" not in test_text:
    raise SystemExit(
        "ERROR: no se encontró la expectativa de validación esperada. "
        "No se modificó ningún archivo."
    )

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = root / f".backup_validacion_nombre_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in (test_path, state_path):
    target = backup_dir / path.relative_to(root)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

if old_test in test_text:
    test_text = test_text.replace(old_test, new_test, 1)
    test_path.write_text(test_text, encoding="utf-8", newline="\n")
    print(f"Modificado: {test_path.relative_to(root)}")
else:
    print("La prueba ya estaba corregida.")

# Mantiene una redacción breve y coherente en la interfaz.
long_message = "Ingresa el nombre comercial del producto."
short_message = "Ingresa el nombre comercial."
if long_message in state_text:
    state_text = state_text.replace(long_message, short_message, 1)
    state_path.write_text(state_text, encoding="utf-8", newline="\n")
    print(f"Modificado: {state_path.relative_to(root)}")

print(f"Respaldo: {backup_dir}")
print("Corrección aplicada.")
