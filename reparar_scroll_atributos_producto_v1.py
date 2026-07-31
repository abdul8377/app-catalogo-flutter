from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

PAGE_PATH = (
    ROOT
    / "lib/features/catalogo/presentation/pages/producto_form_page.dart"
)
FAMILY_ATTRIBUTES_PATH = (
    ROOT
    / "lib/features/catalogo/presentation/widgets/producto_atributos_familia.dart"
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


for path in (PAGE_PATH, FAMILY_ATTRIBUTES_PATH):
    if not path.exists():
        fail(f"No se encontró {path}")


page = PAGE_PATH.read_text(encoding="utf-8")
family = FAMILY_ATTRIBUTES_PATH.read_text(encoding="utf-8")

if "class _PasoFamiliaTipo extends StatelessWidget" not in page:
    fail("No se encontró el paso unificado de producto y variantes.")

if "¿Cómo se organiza este producto?" not in page:
    fail("No se encontró la sección de organización del producto.")

# Reemplaza únicamente el build de _PasoFamiliaTipo.
pattern = re.compile(
    r"""  @override
  Widget build\(BuildContext context\) => LayoutBuilder\(
    builder: \(context, constraints\) \{
      final compact = constraints\.maxWidth < 720;
      return Column\(
        children: \[
          Padding\(
            padding: EdgeInsets\.fromLTRB\(
              compact \? 12 : 20,
              compact \? 10 : 20,
              compact \? 12 : 20,
              0,
            \),
            child: _configurationCard\(context, compact: compact\),
          \),
          SizedBox\(height: compact \? 8 : 14\),
          Expanded\(
            child: AnimatedSwitcher\(
              duration: const Duration\(milliseconds: 220\),
              child: KeyedSubtree\(
                key: ValueKey\('editor-\$\{state\.tipoRegistro\}'\),
                child: switch \(state\.tipoRegistro\) \{
                  'matriz' => ProductoMatrizStep\(state: state\),
                  'unico' => ProductoUnicoStep\(state: state\),
                  _ => ProductoVariantesStep\(state: state\),
                \},
              \),
            \),
          \),
        \],
      \);
    \},
  \);
""",
    re.MULTILINE,
)

replacement = r"""  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      return NestedScrollView(
        key: const Key('producto_estructura_scroll'),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                compact ? 10 : 20,
                compact ? 12 : 20,
                0,
              ),
              child: _configurationCard(context, compact: compact),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: compact ? 8 : 14),
          ),
        ],
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('editor-${state.tipoRegistro}'),
            child: switch (state.tipoRegistro) {
              'matriz' => ProductoMatrizStep(state: state),
              'unico' => ProductoUnicoStep(state: state),
              _ => ProductoVariantesStep(state: state),
            },
          ),
        ),
      );
    },
  );
"""

matches = list(pattern.finditer(page))
if len(matches) != 1:
    fail(
        "No se pudo localizar de forma única la estructura fija del paso. "
        f"Se encontraron {len(matches)} coincidencias."
    )

page_updated = pattern.sub(replacement, page, count=1)

# Aclara la terminología sin alterar la lógica ni los datos.
family_updated = family

old_title = "'Características comunes'"
new_title = "'Atributos comunes'"
if old_title in family_updated:
    family_updated = family_updated.replace(old_title, new_title, 1)
elif new_title not in family_updated:
    fail("No se encontró el título de características comunes.")

old_help = "'Se completan una vez y se aplican a todas las variantes.'"
new_help = (
    "'Datos técnicos que comparten todas las variantes; "
    "se registran una sola vez.'"
)
if old_help in family_updated:
    family_updated = family_updated.replace(old_help, new_help, 1)
elif "Datos técnicos que comparten todas las variantes" not in family_updated:
    fail("No se encontró el texto de ayuda de atributos comunes.")

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_scroll_atributos_producto_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

updates = {
    PAGE_PATH: page_updated,
    FAMILY_ATTRIBUTES_PATH: family_updated,
}

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nScroll unificado y terminología de atributos corregidos.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/flujo_producto_coherencia_test.dart")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
