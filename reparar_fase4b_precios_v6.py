from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()
TARGET = (
    ROOT
    / "lib/features/catalogo/presentation/widgets/paso5_precios_corregido.dart"
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def matching_brace(content: str, brace_index: int) -> int:
    depth = 0
    index = brace_index
    quote: str | None = None
    escaped = False
    line_comment = False
    block_comment = False

    while index < len(content):
        char = content[index]
        nxt = content[index + 1] if index + 1 < len(content) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue

        if block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                index += 2
                continue
            index += 1
            continue

        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue

        if char == "/" and nxt == "/":
            line_comment = True
            index += 2
            continue

        if char == "/" and nxt == "*":
            block_comment = True
            index += 2
            continue

        if char in {"'", '"'}:
            quote = char
            index += 1
            continue

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index

        index += 1

    return -1


if not TARGET.exists():
    fail(f"No se encontró {TARGET}")

content = TARGET.read_text(encoding="utf-8")

if "_selectPriceLists" not in content:
    fail("La fase 4B no parece estar aplicada.")

# El error de compilación reporta exactamente un miembro huérfano que empieza
# al nivel de clase con `) {`. Verificamos además que su cuerpo corresponda
# al antiguo helper de fechas antes de eliminarlo.
matches = list(re.finditer(r"(?m)^\)\s*\{\s*$", content))
candidates: list[tuple[int, int]] = []

for match in matches:
    start = match.start()
    brace = content.find("{", match.start(), match.end())
    if brace < 0:
        continue

    end = matching_brace(content, brace)
    if end < 0:
        continue

    body = content[start : end + 1]
    looks_like_old_date_helper = (
        "OutlinedButton.icon" in body
        and "onTap: onTap" in body
        and "onClear" in body
        and "calendar_today_outlined" in body
    )

    if looks_like_old_date_helper:
        candidates.append((start, end))

if len(candidates) != 1:
    fail(
        "Se esperaba encontrar un único cuerpo huérfano del selector de fecha "
        f"y se encontraron {len(candidates)}."
    )

start, end = candidates[0]

# Conserva como máximo dos saltos de línea entre los miembros vecinos.
prefix = content[:start].rstrip()
suffix = content[end + 1 :].lstrip("\n")
updated = prefix + "\n\n" + suffix

if re.search(r"(?m)^\)\s*\{\s*$", updated):
    fail(
        "Después de preparar la reparación todavía queda un miembro huérfano "
        "con la misma forma."
    )

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_reparacion_fase4b_precios_{timestamp}"
backup_file = backup_dir / TARGET.relative_to(ROOT)
backup_file.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(TARGET, backup_file)

TARGET.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TARGET.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nCuerpo huérfano de _buildDialogDateField eliminado.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/reglas_comerciales_producto_test.dart")
print("  flutter test test/flujo_producto_coherencia_test.dart")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
