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
        ROOT.glob(".backup_estructura_catalogo_fase1_*"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for candidate in candidates:
        if all((candidate / relative).exists() for relative in RELATIVE_FILES):
            return candidate
    fail(
        "No se encontró un respaldo completo .backup_estructura_catalogo_fase1_*."
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


ROBUST_REPLACE_BLOCK = r