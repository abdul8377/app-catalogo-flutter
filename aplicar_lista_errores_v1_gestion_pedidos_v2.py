from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

QUOTE_DIALOG = ROOT / "lib/features/pedidos/presentation/dialogs/generar_cotizacion_dialog.dart"
QUOTE_TOTALS = ROOT / "lib/features/pedidos/presentation/widgets/cotizacion_totales.dart"
QUOTE_PREVIEW = ROOT / "lib/features/pedidos/presentation/widgets/cotizacion_preview.dart"
QUOTE_PRODUCT = ROOT / "lib/features/pedidos/presentation/widgets/cotizacion_producto_item.dart"
ORDER_DETAIL = ROOT / "lib/features/pedidos/presentation/dialogs/pedido_detalle_dialog.dart"
ORDER_FILTERS = ROOT / "lib/features/pedidos/presentation/widgets/pedidos_filtros.dart"
QUOTE_TEST = ROOT / "test/cotizacion_flujo_test.dart"


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


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
    label: str,
) -> str:
    start_count = source.count(start_marker)
    end_count = source.count(end_marker)
    if start_count != 1 or end_count != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio: {start_count}; fin: {end_count}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


required = [
    QUOTE_DIALOG,
    QUOTE_TOTALS,
    QUOTE_PREVIEW,
    QUOTE_PRODUCT,
    ORDER_DETAIL,
    ORDER_FILTERS,
]
for path in required:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

if QUOTE_TEST.exists():
    fail(f"Ya existe {QUOTE_TEST.relative_to(ROOT)}")

sources = {path: path.read_text(encoding="utf-8") for path in required}

if "\\n" in (
    "final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;"
):
    fail("Validación interna inválida de saltos de línea.")

markers = {
    QUOTE_DIALOG: [
        "final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;",
        "vigenciaDias: 0,",
        "condiciones: '',",
        "class _BottomBar extends StatelessWidget",
        "final printableLines = lines.length > 48",
    ],
    QUOTE_TOTALS: [
        "class CotizacionTotalesValue",
        "Total de cotización — incluye IGV",
    ],
    QUOTE_PREVIEW: [
        "class CotizacionPreview extends StatelessWidget",
        "Total de cotización — incluye IGV",
    ],
    QUOTE_PRODUCT: [
        "class CotizacionProductoItem extends StatefulWidget",
        "Precio sugerido:",
    ],
    ORDER_DETAIL: [
        "final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;",
        "Total de cotización — incluye IGV",
    ],
    ORDER_FILTERS: [
        "constraints: const BoxConstraints(maxWidth: 650)",
        "void _aplicar() {",
    ],
}
for path, expected in markers.items():
    for marker in expected:
        if marker not in sources[path]:
            fail(
                f"{path.relative_to(ROOT)} no contiene el marcador esperado: "
                f"{marker}"
            )

quote_dialog = sources[QUOTE_DIALOG]
quote_preview = sources[QUOTE_PREVIEW]
quote_product = sources[QUOTE_PRODUCT]
order_detail = sources[ORDER_DETAIL]
order_filters = sources[ORDER_FILTERS]
quote_totals = "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\nimport 'package:google_fonts/google_fonts.dart';\n\nimport '../../domain/entities/cotizacion_pedido.dart';\n\nclass CotizacionTotalesValue {\n  const CotizacionTotalesValue({\n    required this.descuentoGlobalPorcentaje,\n    required this.descuentoGlobalMonto,\n    required this.observaciones,\n    this.vigenciaDias = 7,\n    this.condiciones = '',\n  });\n\n  final double descuentoGlobalPorcentaje;\n  final double descuentoGlobalMonto;\n  final String observaciones;\n  final int vigenciaDias;\n  final String condiciones;\n\n  double descuentoGeneralSobre(double subtotalNeto) {\n    final porcentaje = descuentoGlobalPorcentaje.clamp(0, 100);\n    final monto = descuentoGlobalMonto < 0 ? 0 : descuentoGlobalMonto;\n    return (subtotalNeto * porcentaje / 100 + monto)\n        .clamp(0, subtotalNeto)\n        .toDouble();\n  }\n}\n\nclass CotizacionTotales extends StatefulWidget {\n  const CotizacionTotales({\n    required this.subtotalProductos,\n    required this.descuentosProductos,\n    required this.value,\n    required this.onChanged,\n    super.key,\n  });\n\n  final double subtotalProductos;\n  final double descuentosProductos;\n  final CotizacionTotalesValue value;\n  final ValueChanged<CotizacionTotalesValue> onChanged;\n\n  @override\n  State<CotizacionTotales> createState() => _CotizacionTotalesState();\n}\n\nclass _CotizacionTotalesState extends State<CotizacionTotales> {\n  static const _yellow = Color(0xFFFFC500);\n  static const _ink = Color(0xFF1F1F1F);\n  static const _muted = Color(0xFF667085);\n  static const _border = Color(0xFFE1E5EA);\n\n  late final TextEditingController _porcentajeController;\n  late final TextEditingController _montoController;\n  late final TextEditingController _vigenciaController;\n  late final TextEditingController _condicionesController;\n  late final TextEditingController _observacionesController;\n\n  double get _subtotalNeto =>\n      (widget.subtotalProductos - widget.descuentosProductos)\n          .clamp(0, double.infinity)\n          .toDouble();\n\n  double get _descuentoGeneral => CotizacionTotalesValue(\n    descuentoGlobalPorcentaje: _parseMoney(_porcentajeController.text),\n    descuentoGlobalMonto: _parseMoney(_montoController.text),\n    observaciones: _observacionesController.text,\n    vigenciaDias: _parseDays(_vigenciaController.text),\n    condiciones: _condicionesController.text,\n  ).descuentoGeneralSobre(_subtotalNeto);\n\n  double get _total => CotizacionCalculo.totalConDescuentos(\n    subtotalProductos: widget.subtotalProductos,\n    descuentosProductos: widget.descuentosProductos,\n    descuentoGeneral: _descuentoGeneral,\n  );\n\n  double get _totalSinIgv => CotizacionIgv.totalSinIgv(_total);\n\n  double get _igv => CotizacionIgv.igvIncluido(_total);\n\n  @override\n  void initState() {\n    super.initState();\n    _porcentajeController = TextEditingController(\n      text: widget.value.descuentoGlobalPorcentaje > 0\n          ? widget.value.descuentoGlobalPorcentaje.toStringAsFixed(2)\n          : '',\n    );\n    _montoController = TextEditingController(\n      text: widget.value.descuentoGlobalMonto > 0\n          ? widget.value.descuentoGlobalMonto.toStringAsFixed(2)\n          : '',\n    );\n    _vigenciaController = TextEditingController(\n      text: widget.value.vigenciaDias.clamp(1, 365).toString(),\n    );\n    _condicionesController = TextEditingController(\n      text: widget.value.condiciones,\n    );\n    _observacionesController = TextEditingController(\n      text: widget.value.observaciones,\n    );\n  }\n\n  @override\n  void dispose() {\n    _porcentajeController.dispose();\n    _montoController.dispose();\n    _vigenciaController.dispose();\n    _condicionesController.dispose();\n    _observacionesController.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) => SingleChildScrollView(\n    padding: const EdgeInsets.all(20),\n    child: Column(\n      crossAxisAlignment: CrossAxisAlignment.stretch,\n      children: [\n        _panel(\n          title: 'Resumen económico',\n          subtitle:\n              'El total se desglosa en importe sin IGV, IGV y total final.',\n          icon: Icons.calculate_outlined,\n          child: Column(\n            children: [\n              _row(\n                'Subtotal de productos',\n                'S/ ${widget.subtotalProductos.toStringAsFixed(2)}',\n              ),\n              _row(\n                'Descuento',\n                '-S/ ${(widget.descuentosProductos + _descuentoGeneral).toStringAsFixed(2)}',\n                color: const Color(0xFFD84315),\n              ),\n              _row(\n                'Total sin IGV',\n                'S/ ${_totalSinIgv.toStringAsFixed(2)}',\n              ),\n              _row('IGV (18 %)', 'S/ ${_igv.toStringAsFixed(2)}'),\n              const Divider(height: 28),\n              _row(\n                'Total de cotización',\n                'S/ ${_total.toStringAsFixed(2)}',\n                emphasize: true,\n              ),\n            ],\n          ),\n        ),\n        const SizedBox(height: 16),\n        _panel(\n          title: 'Descuentos generales',\n          subtitle:\n              'Se aplican después de los descuentos configurados por producto.',\n          icon: Icons.percent_rounded,\n          child: LayoutBuilder(\n            builder: (context, constraints) {\n              final porcentaje = _numberField(\n                controller: _porcentajeController,\n                label: 'Porcentaje global',\n                suffix: '%',\n              );\n              final monto = _numberField(\n                controller: _montoController,\n                label: 'Monto global',\n                prefix: 'S/ ',\n              );\n              if (constraints.maxWidth < 560) {\n                return Column(\n                  children: [porcentaje, const SizedBox(height: 12), monto],\n                );\n              }\n              return Row(\n                children: [\n                  Expanded(child: porcentaje),\n                  const SizedBox(width: 12),\n                  Expanded(child: monto),\n                ],\n              );\n            },\n          ),\n        ),\n        const SizedBox(height: 16),\n        _panel(\n          title: 'Condiciones comerciales',\n          subtitle:\n              'Estos datos se guardan con la cotización y se muestran en la '\n              'vista previa.',\n          icon: Icons.handshake_outlined,\n          child: Column(\n            children: [\n              TextField(\n                key: const Key('cotizacion_vigencia_dias'),\n                controller: _vigenciaController,\n                decoration: _inputDecoration(\n                  'Vigencia',\n                  suffix: 'días',\n                  helper: 'Entre 1 y 365 días.',\n                ),\n                keyboardType: TextInputType.number,\n                inputFormatters: [\n                  FilteringTextInputFormatter.digitsOnly,\n                  LengthLimitingTextInputFormatter(3),\n                ],\n                onChanged: (_) => _notifyChange(),\n              ),\n              const SizedBox(height: 12),\n              TextField(\n                key: const Key('cotizacion_condiciones'),\n                controller: _condicionesController,\n                decoration: _inputDecoration(\n                  'Condiciones comerciales',\n                  helper:\n                      'Ejemplo: forma de pago, disponibilidad o tiempo de '\n                      'entrega.',\n                ),\n                maxLines: 3,\n                onChanged: (_) => _notifyChange(),\n              ),\n              const SizedBox(height: 12),\n              TextField(\n                key: const Key('cotizacion_observaciones'),\n                controller: _observacionesController,\n                decoration: _inputDecoration(\n                  'Observación para el cliente',\n                  helper:\n                      'Información adicional que aparecerá en la cotización.',\n                ),\n                maxLines: 3,\n                onChanged: (_) => _notifyChange(),\n              ),\n            ],\n          ),\n        ),\n      ],\n    ),\n  );\n\n  Widget _panel({\n    required String title,\n    required String subtitle,\n    required IconData icon,\n    required Widget child,\n  }) => Container(\n    padding: const EdgeInsets.all(18),\n    decoration: BoxDecoration(\n      color: Colors.white,\n      borderRadius: BorderRadius.circular(18),\n      border: Border.all(color: _border),\n      boxShadow: const [\n        BoxShadow(\n          color: Color(0x0A000000),\n          blurRadius: 12,\n          offset: Offset(0, 4),\n        ),\n      ],\n    ),\n    child: Column(\n      crossAxisAlignment: CrossAxisAlignment.stretch,\n      children: [\n        Row(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Container(\n              width: 38,\n              height: 38,\n              decoration: BoxDecoration(\n                color: const Color(0xFFFFF4CC),\n                borderRadius: BorderRadius.circular(11),\n              ),\n              child: Icon(icon, color: _ink, size: 20),\n            ),\n            const SizedBox(width: 10),\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  Text(\n                    title,\n                    style: GoogleFonts.inter(\n                      color: _ink,\n                      fontSize: 16,\n                      fontWeight: FontWeight.w900,\n                    ),\n                  ),\n                  const SizedBox(height: 2),\n                  Text(\n                    subtitle,\n                    style: GoogleFonts.inter(\n                      color: _muted,\n                      fontSize: 10,\n                      height: 1.35,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n          ],\n        ),\n        const SizedBox(height: 16),\n        child,\n      ],\n    ),\n  );\n\n  Widget _numberField({\n    required TextEditingController controller,\n    required String label,\n    String? prefix,\n    String? suffix,\n  }) => TextField(\n    controller: controller,\n    decoration: _inputDecoration(\n      label,\n      prefix: prefix,\n      suffix: suffix,\n    ),\n    keyboardType: const TextInputType.numberWithOptions(decimal: true),\n    inputFormatters: [_MoneyInputFormatter()],\n    onChanged: (_) {\n      setState(() {});\n      _notifyChange();\n    },\n  );\n\n  InputDecoration _inputDecoration(\n    String label, {\n    String? prefix,\n    String? suffix,\n    String? helper,\n  }) => InputDecoration(\n    labelText: label,\n    prefixText: prefix,\n    suffixText: suffix,\n    helperText: helper,\n    alignLabelWithHint: true,\n    filled: true,\n    fillColor: const Color(0xFFFCFCFD),\n    border: OutlineInputBorder(\n      borderRadius: BorderRadius.circular(12),\n    ),\n    enabledBorder: OutlineInputBorder(\n      borderRadius: BorderRadius.circular(12),\n      borderSide: const BorderSide(color: _border),\n    ),\n    focusedBorder: OutlineInputBorder(\n      borderRadius: BorderRadius.circular(12),\n      borderSide: const BorderSide(color: _yellow, width: 2),\n    ),\n  );\n\n  Widget _row(\n    String label,\n    String value, {\n    Color? color,\n    bool emphasize = false,\n  }) => Padding(\n    padding: const EdgeInsets.symmetric(vertical: 5),\n    child: Row(\n      children: [\n        Expanded(\n          child: Text(\n            label,\n            style: GoogleFonts.inter(\n              color: _ink,\n              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,\n              fontSize: emphasize ? 16 : 14,\n            ),\n          ),\n        ),\n        Text(\n          value,\n          style: GoogleFonts.inter(\n            fontWeight: FontWeight.w900,\n            fontSize: emphasize ? 18 : 14,\n            color: color,\n          ),\n        ),\n      ],\n    ),\n  );\n\n  void _notifyChange() {\n    widget.onChanged(\n      CotizacionTotalesValue(\n        descuentoGlobalPorcentaje: _parseMoney(\n          _porcentajeController.text,\n        ),\n        descuentoGlobalMonto: _parseMoney(_montoController.text),\n        observaciones: _observacionesController.text.trim(),\n        vigenciaDias: _parseDays(_vigenciaController.text),\n        condiciones: _condicionesController.text.trim(),\n      ),\n    );\n  }\n}\n\nclass _MoneyInputFormatter extends TextInputFormatter {\n  final _allowed = RegExp(r'^\\d*([,.]\\d{0,2})?$');\n\n  @override\n  TextEditingValue formatEditUpdate(\n    TextEditingValue oldValue,\n    TextEditingValue newValue,\n  ) {\n    if (newValue.text.isEmpty || _allowed.hasMatch(newValue.text)) {\n      return newValue;\n    }\n    return oldValue;\n  }\n}\n\ndouble _parseMoney(String value) =>\n    double.tryParse(value.replaceAll(',', '.')) ?? 0;\n\nint _parseDays(String value) {\n  final parsed = int.tryParse(value) ?? 7;\n  return parsed.clamp(1, 365);\n}\n"
quote_test = "import 'package:app_catalogo/features/pedidos/presentation/widgets/cotizacion_totales.dart';\nimport 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  test('el descuento combinado nunca supera el subtotal', () {\n    const value = CotizacionTotalesValue(\n      descuentoGlobalPorcentaje: 80,\n      descuentoGlobalMonto: 500,\n      observaciones: '',\n      vigenciaDias: 15,\n      condiciones: 'Pago contra entrega',\n    );\n\n    expect(value.descuentoGeneralSobre(100), 100);\n    expect(value.vigenciaDias, 15);\n    expect(value.condiciones, 'Pago contra entrega');\n  });\n\n  testWidgets('el resumen usa un total claro y condiciones comerciales', (\n    tester,\n  ) async {\n    await tester.binding.setSurfaceSize(const Size(900, 900));\n    addTearDown(() => tester.binding.setSurfaceSize(null));\n\n    CotizacionTotalesValue? changed;\n    await tester.pumpWidget(\n      MaterialApp(\n        home: Scaffold(\n          body: CotizacionTotales(\n            subtotalProductos: 118,\n            descuentosProductos: 0,\n            value: const CotizacionTotalesValue(\n              descuentoGlobalPorcentaje: 0,\n              descuentoGlobalMonto: 0,\n              observaciones: '',\n            ),\n            onChanged: (value) => changed = value,\n          ),\n        ),\n      ),\n    );\n\n    expect(find.text('Total de cotización'), findsOneWidget);\n    expect(find.textContaining('incluye IGV'), findsNothing);\n    expect(find.byKey(const Key('cotizacion_vigencia_dias')), findsOneWidget);\n    expect(find.byKey(const Key('cotizacion_condiciones')), findsOneWidget);\n\n    await tester.enterText(\n      find.byKey(const Key('cotizacion_vigencia_dias')),\n      '30',\n    );\n    await tester.enterText(\n      find.byKey(const Key('cotizacion_condiciones')),\n      'Pago a 15 días',\n    );\n    await tester.pump();\n\n    expect(changed?.vigenciaDias, 30);\n    expect(changed?.condiciones, 'Pago a 15 días');\n    expect(tester.takeException(), isNull);\n  });\n}\n"

# 1. Modal de cotización más amplio.
quote_dialog = replace_once(
    quote_dialog,
    "        final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;\n"
    "        final height = constraints.maxHeight > 760\n"
    "            ? 760.0\n"
    "            : constraints.maxHeight;\n",
    "        final width = constraints.maxWidth > 1160\n"
    "            ? 1160.0\n"
    "            : constraints.maxWidth;\n"
    "        final height = constraints.maxHeight > 900\n"
    "            ? 900.0\n"
    "            : constraints.maxHeight;\n",
    "dimensiones del modal de cotización",
)
quote_dialog = replace_once(
    quote_dialog,
    "        return Container(\n"
    "          width: width,\n"
    "          height: height,\n",
    "        return Container(\n"
    "          key: const Key('generar_cotizacion_surface'),\n"
    "          width: width,\n"
    "          height: height,\n",
    "clave del modal de cotización",
)

# 2. El resumen incorpora condiciones comerciales.
quote_dialog = replace_once(
    quote_dialog,
    "  CotizacionTotalesValue _totalesValue = const CotizacionTotalesValue(\n"
    "    descuentoGlobalPorcentaje: 0,\n"
    "    descuentoGlobalMonto: 0,\n"
    "    observaciones: '',\n"
    "  );\n",
    "  CotizacionTotalesValue _totalesValue = const CotizacionTotalesValue(\n"
    "    descuentoGlobalPorcentaje: 0,\n"
    "    descuentoGlobalMonto: 0,\n"
    "    observaciones: '',\n"
    "    vigenciaDias: 7,\n"
    "    condiciones: '',\n"
    "  );\n",
    "valores comerciales iniciales",
)
quote_dialog = replace_once(
    quote_dialog,
    "        descuentoGlobalMonto: pedido.descuentoGlobalMonto,\n"
    "        observaciones: pedido.observacionesCotizacion,\n",
    "        descuentoGlobalMonto: pedido.descuentoGlobalMonto,\n"
    "        observaciones: pedido.observacionesCotizacion,\n"
    "        vigenciaDias: 7,\n"
    "        condiciones: '',\n",
    "valores comerciales de edición",
)
quote_dialog = replace_once(
    quote_dialog,
    "          observaciones: _totalesValue.observaciones,\n"
    "        );\n",
    "          observaciones: _totalesValue.observaciones,\n"
    "          vigenciaDias: _totalesValue.vigenciaDias,\n"
    "          condiciones: _totalesValue.condiciones,\n"
    "        );\n",
    "condiciones en la vista previa",
)

# 3. Un borrador sí puede guardarse con precios pendientes.
old_guard = """    if (_saving) return;
    if (!_todosConPrecio) {
      setState(() => _currentStep = 0);
      _continuar();
      return;
    }
    setState(() => _saving = true);
"""
new_guard = """    if (_saving) return;
    final esBorrador = !exportarPdf && !widget.modoEdicion;
    if (!esBorrador && !_todosConPrecio) {
      setState(() => _currentStep = 0);
      _continuar();
      return;
    }
    setState(() => _saving = true);
"""
quote_dialog = replace_once(
    quote_dialog,
    old_guard,
    new_guard,
    "regla de guardado de borrador",
)
quote_dialog = replace_once(
    quote_dialog,
    "        vigenciaDias: 0,\n"
    "        condiciones: '',\n"
    "        observaciones: _totalesValue.observaciones,\n",
    "        vigenciaDias: _totalesValue.vigenciaDias,\n"
    "        condiciones: _totalesValue.condiciones,\n"
    "        observaciones: _totalesValue.observaciones,\n",
    "persistir condiciones de cotización",
)

quote_dialog = replace_once(
    quote_dialog,
    "        total: _totalConDescuento,\n"
    "        observaciones: _totalesValue.observaciones,\n"
    "      );\n",
    "        total: _totalConDescuento,\n"
    "        observaciones: _totalesValue.observaciones,\n"
    "        vigenciaDias: _totalesValue.vigenciaDias,\n"
    "        condiciones: _totalesValue.condiciones,\n"
    "      );\n",
    "condiciones para exportación PDF",
)

# 4. Encabezado de cotización coherente con el sistema.
new_header = """class _Header extends StatelessWidget {
  const _Header({required this.pedido});

  final PedidoDetalle pedido;

  @override
  Widget build(BuildContext context) => Container(
    color: _GenerarCotizacionDialogState.darkColor,
    padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: _GenerarCotizacionDialogState.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.request_quote_outlined,
            color: _GenerarCotizacionDialogState.darkColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generar cotización',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${pedido.codigo} · ${pedido.clienteNombre}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFB7BAC1),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    ),
  );
}
"""
quote_dialog = replace_between(
    quote_dialog,
    "class _Header extends StatelessWidget {",
    "class _StepHeader extends StatelessWidget {",
    new_header,
    "encabezado de cotización",
)

# 5. Barra inferior: borrador disponible antes de completar todos los precios.
new_bottom = """class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentStep,
    required this.saving,
    required this.canContinue,
    required this.onClose,
    required this.onContinue,
    required this.onSaveDraft,
    required this.onExport,
    required this.modoEdicion,
    this.onBack,
  });

  final int currentStep;
  final bool saving;
  final bool canContinue;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final VoidCallback onSaveDraft;
  final VoidCallback onExport;
  final bool modoEdicion;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(24),
      ),
      border: const Border(top: BorderSide(color: Color(0xFFE1E5EA))),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Wrap(
        alignment: WrapAlignment.end,
        runAlignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: saving
                ? null
                : currentStep > 0
                ? onBack
                : onClose,
            child: Text(currentStep > 0 ? 'Volver' : 'Cancelar'),
          ),
          if (!modoEdicion)
            OutlinedButton.icon(
              key: const Key('guardar_borrador_cotizacion'),
              onPressed: saving ? null : onSaveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar borrador'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _GenerarCotizacionDialogState.darkColor,
                side: const BorderSide(color: Color(0xFFFFC500)),
              ),
            ),
          if (currentStep < 2)
            FilledButton.icon(
              onPressed: saving ? null : onContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continuar'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    _GenerarCotizacionDialogState.primaryColor,
                foregroundColor: Colors.black,
              ),
            )
          else
            FilledButton.icon(
              key: const Key('generar_pdf_cotizacion'),
              onPressed: saving || !canContinue ? null : onExport,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                saving
                    ? 'Guardando...'
                    : modoEdicion
                    ? 'Guardar nueva versión'
                    : 'Generar PDF',
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    _GenerarCotizacionDialogState.primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
              ),
            ),
        ],
      ),
    ),
  );
}
"""
quote_dialog = replace_between(
    quote_dialog,
    "class _BottomBar extends StatelessWidget {",
    "class _DialogError extends StatelessWidget {",
    new_bottom,
    "barra inferior de cotización",
)

# 6. Confirmación final de cotización más clara.
new_success = """  Future<void> _mostrarCotizacionGenerada(
    CotizacionPedidoGuardada cotizacion,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 590),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                color: const Color(0xFFECFDF3),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 33,
                      backgroundColor: Color(0xFF12B76A),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Cotización generada',
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cotizacion.codigo} · Versión ${cotizacion.version}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475467),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text(
                      'El PDF quedó guardado localmente y asociado al pedido.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 9,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _ejecutarAccionArchivo(
                            () => FileActionsService.openPdf(
                              cotizacion.pdfPath!,
                            ),
                          ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _ejecutarAccionArchivo(
                            () => FileActionsService.sharePdf(
                              cotizacion.pdfPath!,
                            ),
                          ),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Compartir'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
"""
quote_dialog = replace_between(
    quote_dialog,
    "  Future<void> _mostrarCotizacionGenerada(",
    "  Future<void> _ejecutarAccionArchivo(",
    new_success,
    "confirmación de cotización",
)

# 7. Exportador: conserva todas las líneas usando varias páginas.
quote_dialog = replace_once(
    quote_dialog,
    "    required String observaciones,\n"
    "  }) async {\n",
    "    required String observaciones,\n"
    "    required int vigenciaDias,\n"
    "    required String condiciones,\n"
    "  }) async {\n",
    "parámetros comerciales del exportador",
)
quote_dialog = replace_once(
    quote_dialog,
    "      observaciones: observaciones,\n"
    "    );\n",
    "      observaciones: observaciones,\n"
    "      vigenciaDias: vigenciaDias,\n"
    "      condiciones: condiciones,\n"
    "    );\n",
    "condiciones al construir PDF",
)
quote_dialog = replace_once(
    quote_dialog,
    "    required String observaciones,\n"
    "  }) {\n"
    "    final lines = <String>[\n",
    "    required String observaciones,\n"
    "    required int vigenciaDias,\n"
    "    required String condiciones,\n"
    "  }) {\n"
    "    final lines = <String>[\n",
    "firma de líneas PDF",
)
quote_dialog = replace_once(
    quote_dialog,
    "      'Fecha: ${_formatDate(DateTime.now())}',\n"
    "      '',\n"
    "      'PRODUCTO | CANTIDAD | P. UNITARIO | SUBTOTAL',\n",
    "      'Fecha: ${_formatDate(DateTime.now())}',\n"
    "      'Vigencia: $vigenciaDias días',\n"
    "      if (condiciones.trim().isNotEmpty)\n"
    "        'Condiciones: ${condiciones.trim()}',\n"
    "      '',\n"
    "      'PRODUCTO | CANTIDAD | P. UNITARIO | SUBTOTAL',\n",
    "condiciones dentro del PDF",
)

multi_page_pdf = r'''  List<int> _buildPdf(List<String> lines) {
    const linesPerPage = 48;
    final pages = <List<String>>[];
    if (lines.isEmpty) {
      pages.add(const []);
    } else {
      for (var index = 0; index < lines.length; index += linesPerPage) {
        final candidateEnd = index + linesPerPage;
        final end = candidateEnd < lines.length
            ? candidateEnd
            : lines.length;
        pages.add(lines.sublist(index, end));
      }
    }

    final fontObjectId = 3 + pages.length * 2;
    final pageObjectIds = <int>[];
    final objects = <int, String>{};

    for (var index = 0; index < pages.length; index++) {
      pageObjectIds.add(3 + index * 2);
    }

    objects[1] = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
    objects[2] =
        '2 0 obj\n<< /Type /Pages /Kids '
        '[${pageObjectIds.map((id) => '$id 0 R').join(' ')}] '
        '/Count ${pages.length} >>\nendobj\n';

    for (var index = 0; index < pages.length; index++) {
      final pageObjectId = 3 + index * 2;
      final contentObjectId = pageObjectId + 1;
      final content = StringBuffer()
        ..writeln('BT')
        ..writeln('/F1 10 Tf')
        ..writeln('50 800 Td')
        ..writeln('14 TL');

      if (index > 0) {
        content
          ..writeln('(${_escapePdf('Continuacion ${index + 1}')}) Tj')
          ..writeln('T*');
      }
      for (final line in pages[index]) {
        content
          ..write('(')
          ..write(_escapePdf(_ascii(line)))
          ..writeln(') Tj')
          ..writeln('T*');
      }
      content.writeln('ET');

      final stream = content.toString();
      final streamLength = latin1.encode(stream).length;
      objects[pageObjectId] =
          '$pageObjectId 0 obj\n'
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Contents $contentObjectId 0 R '
          '/Resources << /Font << /F1 $fontObjectId 0 R >> >> >>\n'
          'endobj\n';
      objects[contentObjectId] =
          '$contentObjectId 0 obj\n'
          '<< /Length $streamLength >>\n'
          'stream\n$stream'
          'endstream\nendobj\n';
    }

    objects[fontObjectId] =
        '$fontObjectId 0 obj\n'
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n'
        'endobj\n';

    var pdf = '%PDF-1.4\n';
    final offsets = <int>[];
    for (var objectId = 1; objectId <= fontObjectId; objectId++) {
      final object = objects[objectId];
      if (object == null) {
        throw StateError('Objeto PDF $objectId no generado.');
      }
      offsets.add(latin1.encode(pdf).length);
      pdf += object;
    }

    final startXref = latin1.encode(pdf).length;
    final xref = StringBuffer()
      ..writeln('xref')
      ..writeln('0 ${fontObjectId + 1}')
      ..writeln('0000000000 65535 f ');
    for (final offset in offsets) {
      xref.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    pdf +=
        '${xref}trailer\n'
        '<< /Size ${fontObjectId + 1} /Root 1 0 R >>\n'
        'startxref\n$startXref\n%%EOF';
    return latin1.encode(pdf);
  }
'''
quote_dialog = replace_between(
    quote_dialog,
    "  List<int> _buildPdf(List<String> lines) {",
    "  String _formatDate(DateTime date) =>",
    multi_page_pdf,
    "exportador PDF multipágina",
)

# 8. Vista previa: total claro y condiciones comerciales visibles.
quote_preview = replace_once(
    quote_preview,
    "    required this.observaciones,\n"
    "    this.codigoCotizacion,\n",
    "    required this.observaciones,\n"
    "    required this.vigenciaDias,\n"
    "    required this.condiciones,\n"
    "    this.codigoCotizacion,\n",
    "constructor de vista previa",
)
quote_preview = replace_once(
    quote_preview,
    "  final String observaciones;\n"
    "  final String? codigoCotizacion;\n",
    "  final String observaciones;\n"
    "  final int vigenciaDias;\n"
    "  final String condiciones;\n"
    "  final String? codigoCotizacion;\n",
    "campos comerciales de vista previa",
)
quote_preview = replace_once(
    quote_preview,
    "          if (observaciones.trim().isNotEmpty) ...[\n",
    "          const SizedBox(height: 18),\n"
    "          Wrap(\n"
    "            spacing: 12,\n"
    "            runSpacing: 8,\n"
    "            children: [\n"
    "              _Info(label: 'Vigencia', value: '$vigenciaDias días'),\n"
    "              if (condiciones.trim().isNotEmpty)\n"
    "                _Info(\n"
    "                  label: 'Condiciones',\n"
    "                  value: condiciones.trim(),\n"
    "                ),\n"
    "            ],\n"
    "          ),\n"
    "          if (observaciones.trim().isNotEmpty) ...[\n",
    "condiciones en vista previa",
)

# 9. Producto de cotización: mostrar la presentación como dato comercial,
# sin llamarla variante.
quote_product = replace_once(
    quote_product,
    "                    Text(\n"
    "                      '${prod.cantidad} ${prod.presentacion} • ${prod.equivalenciaTotal}',\n",
    "                    Text(\n"
    "                      '${prod.cantidad} × ${prod.presentacion} · '\n"
    "                      '${prod.equivalencia}',\n",
    "presentación del producto cotizado",
)

# 10. Detalle del pedido más amplio.
order_detail = replace_once(
    order_detail,
    "        final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;\n"
    "        final height = constraints.maxHeight > 760\n"
    "            ? 760.0\n"
    "            : constraints.maxHeight;\n",
    "        final width = constraints.maxWidth > 1120\n"
    "            ? 1120.0\n"
    "            : constraints.maxWidth;\n"
    "        final height = constraints.maxHeight > 900\n"
    "            ? 900.0\n"
    "            : constraints.maxHeight;\n",
    "dimensiones del detalle de pedido",
)

# 11. Filtros: más espacio y validación de rango de fechas.
order_filters = replace_once(
    order_filters,
    "        constraints: const BoxConstraints(maxWidth: 650),\n",
    "        constraints: BoxConstraints(\n"
    "          maxWidth: 760,\n"
    "          maxHeight: MediaQuery.sizeOf(context).height * .9,\n"
    "        ),\n",
    "dimensiones de filtros avanzados",
)
order_filters = replace_once(
    order_filters,
    "  void _aplicar() {\n"
    "    Navigator.pop(\n",
    "  void _aplicar() {\n"
    "    if (_fechaInicio != null &&\n"
    "        _fechaFin != null &&\n"
    "        _fechaInicio!.isAfter(_fechaFin!)) {\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        const SnackBar(\n"
    "          content: Text(\n"
    "            'La fecha inicial no puede ser posterior a la fecha final.',\n"
    "          ),\n"
    "        ),\n"
    "      );\n"
    "      return;\n"
    "    }\n"
    "    Navigator.pop(\n",
    "validación del rango de fechas",
)

# 12. Eliminar la frase redundante en todos los puntos revisados.
for label, content_name in (
    ("generar cotización", "quote_dialog"),
    ("vista previa", "quote_preview"),
    ("detalle de pedido", "order_detail"),
):
    content = locals()[content_name]
    content = content.replace(
        "Total de cotización — incluye IGV",
        "Total de cotización",
    ).replace(
        "Total de cotizacion — incluye IGV",
        "Total de cotización",
    )
    locals()[content_name] = content

updates = {
    QUOTE_DIALOG: quote_dialog,
    QUOTE_TOTALS: quote_totals,
    QUOTE_PREVIEW: quote_preview,
    QUOTE_PRODUCT: quote_product,
    ORDER_DETAIL: order_detail,
    ORDER_FILTERS: order_filters,
    QUOTE_TEST: quote_test,
}

for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado de {path.relative_to(ROOT)} está vacío.")
    if "Total de cotización — incluye IGV" in content:
        fail(
            f"La frase redundante permanece en {path.relative_to(ROOT)}."
        )

backup_dir = ROOT / (
    ".backup_lista_errores_v1_gestion_pedidos_v2_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    if path.exists():
        destination = backup_dir / path.relative_to(ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)

for path, content in updates.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    existed = path.exists()
    path.write_text(content, encoding="utf-8", newline="\n")
    print(
        f"{'Modificado' if existed else 'Creado'}: "
        f"{path.relative_to(ROOT)}"
    )

print(f"\nRespaldo: {backup_dir}")
print("\nFlujo de cotización y ventanas de Gestión de pedidos mejorados con v2.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib test")
print("  flutter test test/cotizacion_flujo_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")