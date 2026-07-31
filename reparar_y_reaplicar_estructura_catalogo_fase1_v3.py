from __future__ import annotations

import ast
from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

ORIGINAL_SCRIPT = ROOT / "aplicar_estructura_catalogo_fase1_coherencia_v1.py"

RELATIVE_FILES = (
    Path(
        "lib/features/estructura_catalogo/presentation/widgets/"
        "estructura_catalogo_corregida.dart"
    ),
    Path(
        "lib/features/estructura_catalogo/presentation/pages/"
        "estructura_catalogo_integrada.dart"
    ),
    Path("test/estructura_catalogo_page_test.dart"),
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se completó la reparación.")


def latest_valid_backup() -> Path:
    candidates = sorted(
        (
            path
            for path in ROOT.glob(".backup_estructura_catalogo_fase1_*")
            if "_rota_" not in path.name
        ),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for candidate in candidates:
        if all((candidate / relative).exists() for relative in RELATIVE_FILES):
            return candidate
    fail(
        "No se encontró un respaldo completo "
        ".backup_estructura_catalogo_fase1_*."
    )
    raise AssertionError


def replace_python_function(
    source: str,
    function_name: str,
    replacement: str,
) -> str:
    tree = ast.parse(source)
    nodes = [
        node
        for node in tree.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
        and node.name == function_name
    ]
    if len(nodes) != 1:
        fail(
            f"No se encontró exactamente una función Python llamada "
            f"{function_name} en el script de fase 1."
        )

    node = nodes[0]
    lines = source.splitlines(keepends=True)
    start = node.lineno - 1
    end = node.end_lineno
    lines[start:end] = [replacement.rstrip() + "\n\n"]
    return "".join(lines)


ROBUST_REPLACE_BLOCK = 'def _scan_member_span(source: str, marker: str, label: str) -> tuple[int, int]:\n    count = source.count(marker)\n    if count != 1:\n        fail(\n            f"No se pudo localizar “{label}”. "\n            f"Se esperaba 1 marcador y se encontraron {count}."\n        )\n\n    start = source.index(marker)\n\n    if marker.lstrip().startswith("class "):\n        opening = source.find("{", start)\n        if opening < 0:\n            fail(f"No se encontró el cuerpo de “{label}”.")\n        closing = _matching_brace(source, opening)\n        end = closing + 1\n        while end < len(source) and source[end] in " \\t\\r\\n":\n            end += 1\n        return start, end\n\n    opening_paren = source.find("(", start)\n    if opening_paren < 0:\n        fail(f"No se encontró la lista de parámetros de “{label}”.")\n\n    depth = 0\n    index = opening_paren\n    quote: str | None = None\n    triple = False\n    line_comment = False\n    block_comment = 0\n    closing_paren = -1\n\n    while index < len(source):\n        char = source[index]\n        next_char = source[index + 1] if index + 1 < len(source) else ""\n\n        if line_comment:\n            if char == "\\n":\n                line_comment = False\n            index += 1\n            continue\n\n        if block_comment:\n            if char == "/" and next_char == "*":\n                block_comment += 1\n                index += 2\n                continue\n            if char == "*" and next_char == "/":\n                block_comment -= 1\n                index += 2\n                continue\n            index += 1\n            continue\n\n        if quote is not None:\n            if triple:\n                if source.startswith(quote * 3, index):\n                    quote = None\n                    triple = False\n                    index += 3\n                    continue\n                index += 1\n                continue\n\n            if char == "\\\\":\n                index += 2\n                continue\n            if char == quote:\n                quote = None\n            index += 1\n            continue\n\n        if char == "/" and next_char == "/":\n            line_comment = True\n            index += 2\n            continue\n\n        if char == "/" and next_char == "*":\n            block_comment = 1\n            index += 2\n            continue\n\n        if char in ("\'", \'"\'):\n            if source.startswith(char * 3, index):\n                quote = char\n                triple = True\n                index += 3\n            else:\n                quote = char\n                index += 1\n            continue\n\n        if char == "(":\n            depth += 1\n        elif char == ")":\n            depth -= 1\n            if depth == 0:\n                closing_paren = index\n                break\n\n        index += 1\n\n    if closing_paren < 0:\n        fail(f"No se encontró el cierre de parámetros de “{label}”.")\n\n    index = closing_paren + 1\n    while index < len(source) and source[index].isspace():\n        index += 1\n\n    for modifier in ("async*", "sync*", "async", "sync"):\n        if source.startswith(modifier, index):\n            index += len(modifier)\n            while index < len(source) and source[index].isspace():\n                index += 1\n            break\n\n    if source.startswith("=>", index):\n        index += 2\n        paren = bracket = brace = 0\n        quote = None\n        triple = False\n        line_comment = False\n        block_comment = 0\n\n        while index < len(source):\n            char = source[index]\n            next_char = source[index + 1] if index + 1 < len(source) else ""\n\n            if line_comment:\n                if char == "\\n":\n                    line_comment = False\n                index += 1\n                continue\n\n            if block_comment:\n                if char == "/" and next_char == "*":\n                    block_comment += 1\n                    index += 2\n                    continue\n                if char == "*" and next_char == "/":\n                    block_comment -= 1\n                    index += 2\n                    continue\n                index += 1\n                continue\n\n            if quote is not None:\n                if triple:\n                    if source.startswith(quote * 3, index):\n                        quote = None\n                        triple = False\n                        index += 3\n                        continue\n                    index += 1\n                    continue\n\n                if char == "\\\\":\n                    index += 2\n                    continue\n                if char == quote:\n                    quote = None\n                index += 1\n                continue\n\n            if char == "/" and next_char == "/":\n                line_comment = True\n                index += 2\n                continue\n\n            if char == "/" and next_char == "*":\n                block_comment = 1\n                index += 2\n                continue\n\n            if char in ("\'", \'"\'):\n                if source.startswith(char * 3, index):\n                    quote = char\n                    triple = True\n                    index += 3\n                else:\n                    quote = char\n                    index += 1\n                continue\n\n            if char == "(":\n                paren += 1\n            elif char == ")":\n                paren -= 1\n            elif char == "[":\n                bracket += 1\n            elif char == "]":\n                bracket -= 1\n            elif char == "{":\n                brace += 1\n            elif char == "}":\n                brace -= 1\n            elif (\n                char == ";"\n                and paren == 0\n                and bracket == 0\n                and brace == 0\n            ):\n                end = index + 1\n                while end < len(source) and source[end] in " \\t\\r\\n":\n                    end += 1\n                return start, end\n\n            index += 1\n\n        fail(f"No se encontró el final de la expresión “{label}”.")\n\n    if index >= len(source) or source[index] != "{":\n        preview = source[index : index + 40].replace("\\n", "\\\\n")\n        fail(\n            f"No se encontró el cuerpo real de “{label}”. "\n            f"Contenido encontrado: {preview!r}"\n        )\n\n    closing = _matching_brace(source, index)\n    end = closing + 1\n    while end < len(source) and source[end] in " \\t\\r\\n":\n        end += 1\n    return start, end\n\n\ndef replace_block(source: str, marker: str, replacement: str, label: str) -> str:\n    start, end = _scan_member_span(source, marker, label)\n    return source[:start] + replacement.rstrip() + "\\n\\n" + source[end:]'

ROBUST_REMOVE_MEMBER = 'def remove_member(source: str, marker: str, label: str) -> str:\n    start, end = _scan_member_span(source, marker, label)\n    return source[:start] + source[end:]'


if not ORIGINAL_SCRIPT.exists():
    fail(f"No se encontró {ORIGINAL_SCRIPT.name} en la raíz del proyecto.")

backup = latest_valid_backup()

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
broken_backup = ROOT / f".backup_estructura_catalogo_fase1_rota_{timestamp}"

for relative in RELATIVE_FILES:
    current = ROOT / relative
    if current.exists():
        destination = broken_backup / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(current, destination)

for relative in RELATIVE_FILES:
    source = backup / relative
    destination = ROOT / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)

print(f"Restaurado desde: {backup}")
print(f"Estado roto respaldado en: {broken_backup}")

phase_source = ORIGINAL_SCRIPT.read_text(encoding="utf-8")
phase_source = replace_python_function(
    phase_source,
    "replace_block",
    ROBUST_REPLACE_BLOCK,
)
phase_source = replace_python_function(
    phase_source,
    "remove_member",
    ROBUST_REMOVE_MEMBER,
)

compile(phase_source, str(ORIGINAL_SCRIPT), "exec")

namespace = {
    "__name__": "__main__",
    "__file__": str(ORIGINAL_SCRIPT),
}
exec(compile(phase_source, str(ORIGINAL_SCRIPT), "exec"), namespace)

print("\nRecuperación y reaplicación completadas.")
print(
    "No ejecutes nuevamente "
    "aplicar_estructura_catalogo_fase1_coherencia_v1.py."
)
