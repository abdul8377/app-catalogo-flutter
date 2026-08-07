from pathlib import Path
import sys

TARGET = Path("test/producto_form_page_test.dart")

REPLACEMENTS = {
    "expect(bloc.state.presentaciones.single.unidad, '12 PZA');":
        "expect(bloc.state.presentaciones.single.unidad, '12 UND');",
    "find.text('12 PZA · Pedido mínimo: 1 · Incremento: 1'),":
        "find.text('12 UND · Pedido mínimo: 1 · Incremento: 1'),",
}

def main():
    if not TARGET.exists():
        raise SystemExit(
            "No se encontro test/producto_form_page_test.dart. "
            "Ejecuta este script desde la raiz de app_catalogo."
        )

    content = TARGET.read_text(encoding="utf-8")
    original = content

    for old, new in REPLACEMENTS.items():
        if new in content:
            print(f"Ya corregido: {new}")
            continue

        count = content.count(old)
        if count != 1:
            raise SystemExit(
                "No se pudo aplicar una correccion de forma segura. "
                f"Coincidencias para {old!r}: {count}"
            )

        content = content.replace(old, new, 1)
        print(f"Corregido: {old} -> {new}")

    if content != original:
        TARGET.write_text(content, encoding="utf-8", newline="\n")
        print("Archivo actualizado.")
    else:
        print("No habia cambios pendientes.")

    print()
    print("Ejecuta ahora:")
    print(
        r'  & "D:\flutter\bin\dart.bat" format '
        r'test/producto_form_page_test.dart'
    )
    print(
        r'  & "D:\flutter\bin\flutter.bat" test '
        r'test/producto_form_page_test.dart --no-pub '
        r'--plain-name "el paso 4 configura venta, logística y contenido sin desbordar"'
    )
    print(
        r'  & "D:\flutter\bin\flutter.bat" test --no-pub '
        r'--exclude-tags baseline-known-failure'
    )

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
