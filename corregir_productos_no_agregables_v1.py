from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "43c6b44d227e9ca2d3d11eddd95ecd2eedec19b0"

RESOLVER = ROOT / (
    "lib/features/pedidos/domain/services/producto_pedido_resolver.dart"
)
DIALOG = ROOT / (
    "lib/features/pedidos/presentation/widgets/agregar_producto_dialog.dart"
)
TEST = ROOT / "test/producto_pedido_resolver_test.dart"


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


try:
    head = subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        text=True,
    ).strip()
except Exception as error:
    fail(f"No se pudo leer el commit actual: {error}")

if head != EXPECTED_HEAD:
    fail(
        "El repositorio local no está en el commit validado. "
        f"Esperado: {EXPECTED_HEAD}; actual: {head}."
    )

for path in (RESOLVER, DIALOG):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

if TEST.exists():
    fail(f"Ya existe {TEST.relative_to(ROOT)}")

resolver = RESOLVER.read_text(encoding="utf-8")
dialog = DIALOG.read_text(encoding="utf-8")

resolver_old = """      result[lista.id] = PrecioPedidoResuelto(
        lista: lista,
        tipo: TipoPrecioPedido.pendiente,
      );
"""
resolver_new = """      // La ausencia de una fila de precio no invalida una combinación
      // vendible. El vendedor puede agregarla y valorizarla después en la
      // cotización. Solo una configuración explícita pendiente continúa
      // bloqueando la venta.
      result[lista.id] = PrecioPedidoResuelto(
        lista: lista,
        tipo: TipoPrecioPedido.cotizar,
      );
"""
resolver = replace_once(
    resolver,
    resolver_old,
    resolver_new,
    "precio ausente como Por cotizar",
)

dialog_old = """                  if (presentation != null) ...[
                    const SizedBox(height: 12),
                    _summary(
                      presentation: presentation,
                      price: price,
                      unitPrice: unitPrice,
                      quantityValid: quantityValid,
                    ),
                  ],
"""
dialog_new = """                  if (presentation != null) ...[
                    const SizedBox(height: 12),
                    _summary(
                      presentation: presentation,
                      price: price,
                      unitPrice: unitPrice,
                      quantityValid: quantityValid,
                    ),
                    if (price?.tipo == TipoPrecioPedido.cotizar &&
                        unitPrice == null) ...[
                      const SizedBox(height: 10),
                      const _Notice(
                        message:
                            'Esta combinación se agregará sin precio y '
                            'quedará marcada como Por cotizar.',
                      ),
                    ] else if (price?.tipo == TipoPrecioPedido.pendiente) ...[
                      const SizedBox(height: 10),
                      const _Notice(
                        message:
                            'Esta combinación está pendiente de configuración '
                            'comercial. Completa su precio o márcala como '
                            'Por cotizar antes de venderla.',
                        danger: true,
                      ),
                    ],
                  ],
"""
dialog = replace_once(
    dialog,
    dialog_old,
    dialog_new,
    "explicación del estado comercial",
)

test = r"""import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/pedidos/domain/services/producto_pedido_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una combinación sin precio se permite como Por cotizar', () {
    final resolved = ProductoPedidoResolver.resolver(
      _producto(precios: const []),
    );

    final price = resolved
        .variantesActivas
        .single
        .presentaciones
        .single
        .precioParaLista('regular');

    expect(price, isNotNull);
    expect(price!.tipo, TipoPrecioPedido.cotizar);
    expect(price.permiteAgregar, isTrue);
    expect(price.precioPara(1), isNull);
  });

  test('una configuración explícitamente pendiente continúa bloqueada', () {
    final resolved = ProductoPedidoResolver.resolver(
      _producto(
        precios: const [
          {
            'list_id': 'regular',
            'variant_id': 'var-1',
            'presentation_id': 'ciento',
            'configuration': 'pending',
            'fixed_price': null,
            'ranges': [],
          },
        ],
      ),
    );

    final price = resolved
        .variantesActivas
        .single
        .presentaciones
        .single
        .precioParaLista('regular');

    expect(price, isNotNull);
    expect(price!.tipo, TipoPrecioPedido.pendiente);
    expect(price.permiteAgregar, isFalse);
  });
}

ProductoDetalle _producto({
  required List<Map<String, Object?>> precios,
}) => ProductoDetalle(
  id: 'family',
  codigo: 'PER-FAM',
  nombre: 'Perno hexagonal 1/4 x 4',
  descripcion: '',
  empresa: 'DINA',
  marca: 'DINA',
  categoria: 'Pernería',
  subcategoria: 'Pernos',
  tipoRegistro: 'matriz',
  atributos: const {'Material': 'Acero'},
  variantes: const [
    ProductoVariante(
      id: 'var-1',
      sku: 'PER-025X4',
      nombreCorto: 'Perno hexagonal 1/4 x 4',
      atributos: [
        AtributoProductoVariante(
          nombre: 'Diámetro',
          valor: '1/4',
          unidad: 'in',
        ),
        AtributoProductoVariante(
          nombre: 'Largo',
          valor: '4',
          unidad: 'in',
        ),
      ],
    ),
  ],
  presentaciones: const [
    PresentacionProducto(nombre: 'Ciento', unidad: '100 UND'),
  ],
  precios: const [],
  ventaLogisticaContenido: const {
    'presentations': [
      {
        'id': 'ciento',
        'name': 'Ciento',
        'base_unit': 'UND',
        'equivalent_to': 100,
        'minimum_order': 1,
        'purchase_increment': 1,
        'assigned_variant_ids': ['var-1'],
        'default_variant_ids': ['var-1'],
        'variant_rules': [],
      },
    ],
  },
  preciosConfigurados: {
    'lists': const [
      {
        'id': 'regular',
        'name': 'Regular',
        'currency_code': 'PEN',
        'includes_igv': true,
      },
    ],
    'prices': precios,
  },
  activo: true,
  creadoEn: DateTime(2026),
);
"""

for marker in (
    "tipo: TipoPrecioPedido.cotizar",
    "quedará marcada como Por cotizar",
    "TipoPrecioPedido.pendiente",
):
    combined = resolver + dialog + test
    if marker not in combined:
        fail(f"No quedó presente la validación esperada: {marker}")

backup_dir = ROOT / (
    ".backup_agregar_producto_por_cotizar_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in (RESOLVER, DIALOG):
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

RESOLVER.write_text(resolver, encoding="utf-8", newline="\n")
DIALOG.write_text(dialog, encoding="utf-8", newline="\n")
TEST.write_text(test, encoding="utf-8", newline="\n")

print(f"Modificado: {RESOLVER.relative_to(ROOT)}")
print(f"Modificado: {DIALOG.relative_to(ROOT)}")
print(f"Creado: {TEST.relative_to(ROOT)}")
print(f"\nRespaldo: {backup_dir}")
print("\nLos precios ausentes ahora se agregan como Por cotizar.")
print("Las configuraciones explícitamente pendientes continúan bloqueadas.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib test")
print("  flutter test test/producto_pedido_resolver_test.dart")
print("  flutter test test/agregar_producto_dialog_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")
