from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "599e549b02d476201ca7bf5f92e25fb2207db1a8"

PUBSPEC = ROOT / "pubspec.yaml"
QUOTE_DIALOG = ROOT / (
    "lib/features/pedidos/presentation/dialogs/generar_cotizacion_dialog.dart"
)
PDF_SERVICE = ROOT / (
    "lib/features/pedidos/data/services/cotizacion_pdf_service.dart"
)
CODE_GENERATOR = ROOT / (
    "lib/features/catalogo/domain/services/codigo_interno_generator.dart"
)
FORM_BLOC = ROOT / (
    "lib/features/catalogo/presentation/bloc/producto_form_bloc.dart"
)
FORM_PAGE = ROOT / (
    "lib/features/catalogo/presentation/pages/producto_form_page.dart"
)
SINGLE_STEP = ROOT / (
    "lib/features/catalogo/presentation/widgets/producto_unico_step.dart"
)
VARIANTS_STEP = ROOT / (
    "lib/features/catalogo/presentation/widgets/producto_variantes_step.dart"
)
MATRIX_STEP = ROOT / (
    "lib/features/catalogo/presentation/widgets/producto_matriz_step.dart"
)
CODE_TEST = ROOT / "test/codigo_interno_generator_test.dart"
PDF_TEST = ROOT / "test/cotizacion_pdf_service_test.dart"

MODIFIED_PATHS = [
    PUBSPEC,
    QUOTE_DIALOG,
    CODE_GENERATOR,
    FORM_BLOC,
    FORM_PAGE,
    SINGLE_STEP,
    VARIANTS_STEP,
    MATRIX_STEP,
]
NEW_PATHS = [PDF_SERVICE, CODE_TEST, PDF_TEST]


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
    starts = source.count(start_marker)
    ends = source.count(end_marker)
    if starts != 1 or ends != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio: {starts}; fin: {ends}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


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

for path in MODIFIED_PATHS:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

for path in NEW_PATHS:
    if path.exists():
        fail(f"Ya existe {path.relative_to(ROOT)}")

sources = {
    path: path.read_text(encoding="utf-8")
    for path in MODIFIED_PATHS
}

pubspec = sources[PUBSPEC]
quote_dialog = sources[QUOTE_DIALOG]
generator = sources[CODE_GENERATOR]
form_bloc = sources[FORM_BLOC]
form_page = sources[FORM_PAGE]
single_step = sources[SINGLE_STEP]
variants_step = sources[VARIANTS_STEP]
matrix_step = sources[MATRIX_STEP]

# ---------------------------------------------------------------------------
# 1. PDF profesional con el diseño aprobado.
# ---------------------------------------------------------------------------
pubspec = replace_once(
    pubspec,
    "  path_provider: 2.1.6\n",
    "  path_provider: 2.1.6\n  pdf: ^3.13.0\n",
    "dependencia pdf",
)

old_quote_imports = """import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

"""
new_quote_imports = """import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

"""
quote_dialog = replace_once(
    quote_dialog,
    old_quote_imports,
    new_quote_imports,
    "imports del generador PDF anterior",
)
quote_dialog = replace_once(
    quote_dialog,
    "import '../../../../core/presentation/widgets/app_notice.dart';\n",
    """import '../../../../core/presentation/widgets/app_notice.dart';
import '../../data/services/cotizacion_pdf_service.dart';
""",
    "import del servicio PDF",
)
quote_dialog = replace_once(
    quote_dialog,
    "  final _pdfExporter = _CotizacionPdfExporter();\n",
    "  final _pdfExporter = CotizacionPdfService();\n",
    "instancia del servicio PDF",
)

old_pdf_call = """      final pdfPath = await _pdfExporter.exportar(
        cotizacion: guardada,
        pedido: pedido,
        productos: _productos,
        subtotalProductos: _subtotalProductos,
        descuentosProductos: _descuentosProductos,
        descuentoGeneral: _descuentoGeneral,
        total: _totalConDescuento,
        observaciones: _totalesValue.observaciones,
        vigenciaDias: _totalesValue.vigenciaDias,
        condiciones: _totalesValue.condiciones,
      );
"""
new_pdf_call = """      final pdfPath = await _pdfExporter.exportar(
        cotizacion: guardada,
        pedido: pedido,
        productos: _productos
            .map(
              (item) => CotizacionPdfProducto(
                producto: item.producto,
                precioUnitarioConIgv: item.precioCotizacion,
                subtotalConIgv: item.subtotalSinDescuento,
              ),
            )
            .toList(),
        subtotalProductos: _subtotalProductos,
        descuentosProductos: _descuentosProductos,
        descuentoGeneral: _descuentoGeneral,
        total: _totalConDescuento,
        observaciones: _totalesValue.observaciones,
      );
"""
quote_dialog = replace_once(
    quote_dialog,
    old_pdf_call,
    new_pdf_call,
    "datos enviados al nuevo PDF",
)

pdf_exporter_marker = "class _CotizacionPdfExporter {\n"
if quote_dialog.count(pdf_exporter_marker) != 1:
    fail(
        "No se encontró de forma única el exportador PDF manual "
        f"({quote_dialog.count(pdf_exporter_marker)} coincidencias)."
    )
quote_dialog = quote_dialog[: quote_dialog.index(pdf_exporter_marker)].rstrip() + "\n"

pdf_service = r"""import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido_detalle.dart';

class CotizacionPdfProducto {
  const CotizacionPdfProducto({
    required this.producto,
    required this.precioUnitarioConIgv,
    required this.subtotalConIgv,
  });

  final PedidoDetalleProducto producto;
  final double precioUnitarioConIgv;
  final double subtotalConIgv;

  String get codigo {
    final variante = producto.varianteSku.trim();
    return variante.isEmpty ? producto.codigo.trim() : variante;
  }

  String get descripcion {
    final partes = <String>[];
    final variante = producto.varianteNombre.trim();
    if (variante.isNotEmpty &&
        variante.toLowerCase() != producto.nombre.trim().toLowerCase()) {
      partes.add(variante);
    }
    final atributos = producto.atributosVariante.entries
        .where(
          (entry) =>
              entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
        )
        .map((entry) => '${entry.key.trim()}: ${entry.value.trim()}')
        .join(' · ');
    if (atributos.isNotEmpty) partes.add(atributos);
    return partes.join(' · ');
  }
}

class CotizacionPdfService {
  static const _empresa = 'MULTIMARCA';
  static const _actividad = 'Distribución y venta multimarca';
  static const _direccion =
      'ASC. URB. CIUDAD DE DIOS ZN3 SEC. B MZ. 0 LT. 16, CALLE 35 - YURA';
  static const _ciudad = 'AREQUIPA - PERÚ';
  static const _ruc = '10024297506';
  static const _telefono = '948 707 390';

  static const _yellow = PdfColor(1, 0.772549, 0);
  static const _dark = PdfColor(0.121568, 0.121568, 0.121568);
  static const _muted = PdfColor(0.4, 0.439216, 0.521569);
  static const _light = PdfColor(0.960784, 0.964706, 0.972549);
  static const _border = PdfColor(0.85098, 0.862745, 0.882353);

  Future<String> exportar({
    required CotizacionPedidoGuardada cotizacion,
    required PedidoDetalle pedido,
    required List<CotizacionPdfProducto> productos,
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
    required double total,
    required String observaciones,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final folder = Directory(path.join(directory.path, 'cotizaciones'));
    if (!folder.existsSync()) await folder.create(recursive: true);
    final file = File(
      path.join(folder.path, '${cotizacion.codigoVersion}.pdf'),
    );
    final bytes = await generarBytes(
      cotizacion: cotizacion,
      pedido: pedido,
      productos: productos,
      subtotalProductos: subtotalProductos,
      descuentosProductos: descuentosProductos,
      descuentoGeneral: descuentoGeneral,
      total: total,
      observaciones: observaciones,
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List> generarBytes({
    required CotizacionPedidoGuardada cotizacion,
    required PedidoDetalle pedido,
    required List<CotizacionPdfProducto> productos,
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
    required double total,
    required String observaciones,
  }) async {
    final document = pw.Document(
      title: 'Cotización ${cotizacion.codigoVersion}',
      author: _empresa,
      creator: 'App Catálogo',
      subject: 'Cotización comercial',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 52),
        footer: (context) => _footer(context),
        build: (context) => [
          _encabezado(cotizacion),
          pw.SizedBox(height: 14),
          _cliente(pedido),
          pw.SizedBox(height: 14),
          _productos(productos),
          pw.SizedBox(height: 14),
          _cierre(
            subtotalProductos: subtotalProductos,
            descuentosProductos: descuentosProductos,
            descuentoGeneral: descuentoGeneral,
            total: total,
            observaciones: observaciones,
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _encabezado(CotizacionPedidoGuardada cotizacion) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 6,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 9),
              decoration: pw.BoxDecoration(
                color: _yellow,
                border: pw.Border.all(color: _dark, width: .8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _empresa,
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    _actividad,
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(_direccion, style: const pw.TextStyle(fontSize: 8.1)),
            pw.Text(_ciudad, style: const pw.TextStyle(fontSize: 8.1)),
            pw.SizedBox(height: 2),
            pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 8.1, color: _dark),
                children: [
                  pw.TextSpan(
                    text: 'R.U.C.: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: _ruc),
                  const pw.TextSpan(text: '    '),
                  pw.TextSpan(
                    text: 'Teléfono: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: _telefono),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 24),
      pw.Expanded(
        flex: 4,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'COTIZACIÓN',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _dark,
              ),
            ),
            pw.SizedBox(height: 7),
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: .5),
              columnWidths: const {
                0: pw.FixedColumnWidth(64),
                1: pw.FlexColumnWidth(),
              },
              children: [
                _datoCotizacion('N.º:', cotizacion.codigoVersion),
                _datoCotizacion('Fecha:', _fecha(cotizacion.creadoEn)),
                _datoCotizacion('Moneda:', 'Soles (PEN)'),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  pw.TableRow _datoCotizacion(String label, String value) => pw.TableRow(
    children: [
      pw.Container(
        color: _light,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          label,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
      ),
    ],
  );

  pw.Widget _cliente(PedidoDetalle pedido) {
    final documento = [
      if (pedido.clienteRuc.trim().isNotEmpty)
        'RUC: ${pedido.clienteRuc.trim()}',
      if (pedido.clienteDni.trim().isNotEmpty)
        'DNI: ${pedido.clienteDni.trim()}',
    ].join('    ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          color: _dark,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(8, 9, 8, 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _lineaCliente(
                'Cliente / Razón social:',
                pedido.clienteNombre.trim(),
              ),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 22,
                runSpacing: 4,
                children: [
                  if (documento.isNotEmpty)
                    _lineaCliente('RUC / DNI:', documento),
                  _lineaCliente('Teléfono:', pedido.telefono.trim()),
                ],
              ),
              pw.SizedBox(height: 4),
              _lineaCliente(
                'Dirección de entrega:',
                pedido.direccion.trim(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _lineaCliente(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      style: const pw.TextStyle(fontSize: 8.4, color: _dark),
      children: [
        pw.TextSpan(
          text: '$label ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value.isEmpty ? 'No especificado' : value),
      ],
    ),
  );

  pw.Widget _productos(List<CotizacionPdfProducto> productos) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _yellow),
        children: [
          _headerCell('Ítem'),
          _headerCell('Código'),
          _headerCell('Producto / descripción'),
          _headerCell('Presentación'),
          _headerCell('Cant.'),
          _headerCell('P. unitario\n(sin IGV)'),
          _headerCell('Subtotal\n(sin IGV)'),
        ],
      ),
    ];
    for (var index = 0; index < productos.length; index++) {
      final item = productos[index];
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: index.isOdd ? _light : PdfColors.white,
          ),
          children: [
            _bodyCell('${index + 1}', align: pw.TextAlign.center),
            _bodyCell(item.codigo, align: pw.TextAlign.center),
            _productCell(item),
            _presentationCell(item.producto),
            _bodyCell(
              '${item.producto.cantidad}',
              align: pw.TextAlign.center,
            ),
            _bodyCell(
              _money(
                CotizacionIgv.totalSinIgv(item.precioUnitarioConIgv),
              ),
              align: pw.TextAlign.right,
            ),
            _bodyCell(
              _money(CotizacionIgv.totalSinIgv(item.subtotalConIgv)),
              align: pw.TextAlign.right,
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(.55),
        1: pw.FlexColumnWidth(1.05),
        2: pw.FlexColumnWidth(3.35),
        3: pw.FlexColumnWidth(1.45),
        4: pw.FlexColumnWidth(.7),
        5: pw.FlexColumnWidth(1.45),
        6: pw.FlexColumnWidth(1.5),
      },
      children: rows,
    );
  }

  pw.Widget _headerCell(String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    child: pw.Text(
      value,
      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _bodyCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    child: pw.Text(
      value,
      textAlign: align,
      style: const pw.TextStyle(fontSize: 7),
    ),
  );

  pw.Widget _productCell(CotizacionPdfProducto item) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.producto.nombre,
          style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
        ),
        if (item.descripcion.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            item.descripcion,
            style: const pw.TextStyle(fontSize: 6.7, color: _dark),
          ),
        ],
      ],
    ),
  );

  pw.Widget _presentationCell(PedidoDetalleProducto producto) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          producto.presentacion,
          style: const pw.TextStyle(fontSize: 7),
        ),
        if (producto.equivalencia.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            producto.equivalencia.trim(),
            style: const pw.TextStyle(fontSize: 6.4, color: _muted),
          ),
        ],
      ],
    ),
  );

  pw.Widget _cierre({
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
    required double total,
    required String observaciones,
  }) {
    final descuento = descuentosProductos + descuentoGeneral;
    final valorVenta = CotizacionIgv.totalSinIgv(total);
    final igv = CotizacionIgv.igvIncluido(total);
    final observacion = observaciones.trim().isEmpty
        ? 'Los precios unitarios y subtotales se muestran sin IGV. '
              'Stock, disponibilidad y fecha de entrega están sujetos a '
              'confirmación al momento de registrar el pedido.'
        : observaciones.trim();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 7,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border, width: .5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  color: _light,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: pw.Text(
                    'OBSERVACIONES',
                    style: pw.TextStyle(
                      fontSize: 8.4,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    observacion,
                    style: const pw.TextStyle(fontSize: 7.8, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 5,
          child: pw.Table(
            border: pw.TableBorder.all(color: _border, width: .5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.35),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              _totalRow(
                'Subtotal productos',
                _money(CotizacionIgv.totalSinIgv(subtotalProductos)),
              ),
              _totalRow(
                'Descuento',
                '- ${_money(CotizacionIgv.totalSinIgv(descuento))}',
              ),
              _totalRow('Valor de venta', _money(valorVenta)),
              _totalRow('IGV (18%)', _money(igv)),
              _totalRow(
                'TOTAL CON IGV',
                _money(total),
                highlighted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.TableRow _totalRow(
    String label,
    String value, {
    bool highlighted = false,
  }) => pw.TableRow(
    decoration: pw.BoxDecoration(
      color: highlighted ? _yellow : PdfColors.white,
      border: highlighted ? pw.Border.all(color: _dark, width: 1) : null,
    ),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: highlighted ? 9.5 : 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: highlighted ? 10.5 : 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  pw.Widget _footer(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 7),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border, width: .5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Documento comercial - No constituye comprobante de pago.',
          style: const pw.TextStyle(fontSize: 6.8, color: _muted),
        ),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 6.8, color: _muted),
        ),
      ],
    ),
  );

  String _fecha(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return 'S/ ${buffer}.${parts.last}';
  }
}
"""

# ---------------------------------------------------------------------------
# 2. Códigos legibles por familia y variantes.
# ---------------------------------------------------------------------------
generator = r"""abstract final class CodigoInternoGenerator {
  static const _palabrasIgnoradas = {
    'DE',
    'DEL',
    'LA',
    'LAS',
    'EL',
    'LOS',
    'PARA',
    'CON',
    'Y',
    'EN',
    'POR',
    'UN',
    'UNA',
  };

  static String prefijoDesdeNombre(String nombre) {
    var normalizado = nombre.trim().toUpperCase();
    const reemplazos = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    reemplazos.forEach((origen, destino) {
      normalizado = normalizado.replaceAll(origen, destino);
    });
    final palabras = normalizado
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((palabra) => palabra.isNotEmpty)
        .toList();
    final significativas = palabras
        .where((palabra) => !_palabrasIgnoradas.contains(palabra))
        .toList();
    final base = significativas.isNotEmpty
        ? significativas.first
        : palabras.isNotEmpty
        ? palabras.first
        : 'PRD';
    final letras = base.replaceAll(RegExp(r'[^A-Z]'), '');
    if (letras.length >= 3) return letras.substring(0, 3);
    final combinadas = significativas.join().replaceAll(
      RegExp(r'[^A-Z]'),
      '',
    );
    return '${combinadas}PRD'.substring(0, 3);
  }

  static String siguienteProducto({
    required String nombreBase,
    required Iterable<String> codigosExistentes,
  }) {
    final prefijo = prefijoDesdeNombre(nombreBase);
    final pattern = RegExp('^${RegExp.escape(prefijo)}-(\\d+)\$');
    var mayor = 0;
    for (final codigo in codigosExistentes) {
      final match = pattern.firstMatch(codigo.trim().toUpperCase());
      final numero = int.tryParse(match?.group(1) ?? '');
      if (numero != null && numero > mayor) mayor = numero;
    }
    return '$prefijo-${(mayor + 1).toString().padLeft(3, '0')}';
  }

  static String codigoProductoUnico(String codigoFamilia) {
    final limpio = codigoFamilia.trim().toUpperCase();
    return limpio.isEmpty ? 'PRD-001' : limpio;
  }

  static String siguienteVariante({
    required String codigoFamilia,
    required Iterable<String> codigosExistentes,
  }) {
    final familia = codigoFamilia.trim().toUpperCase().isEmpty
        ? 'PRD-001'
        : codigoFamilia.trim().toUpperCase();
    final pattern = RegExp(
      '^${RegExp.escape(familia)}-(\\d+)\$',
    );
    var mayor = 0;
    for (final codigo in codigosExistentes) {
      final match = pattern.firstMatch(codigo.trim().toUpperCase());
      final numero = int.tryParse(match?.group(1) ?? '');
      if (numero != null && numero > mayor) mayor = numero;
    }
    return '$familia-${(mayor + 1).toString().padLeft(3, '0')}';
  }
}
"""

old_family_handler = """    on<ProductoFormFamiliaCambiada>(
      (event, emit) => emit(
        state.copyWith(
          codigo: event.codigo,
          nombre: event.nombre,
          descripcion: event.descripcion,
          limpiarError: true,
        ),
      ),
    );
"""
form_bloc = replace_once(
    form_bloc,
    old_family_handler,
    "    on<ProductoFormFamiliaCambiada>(_familiaCambiada);\n",
    "generación automática al cambiar la familia",
)
form_bloc = replace_once(
    form_bloc,
    """            codigo: CodigoInternoGenerator.nuevoProducto(),
""",
    """            codigo: '',
""",
    "código inicial vacío",
)

family_method = r"""  Future<void> _familiaCambiada(
    ProductoFormFamiliaCambiada event,
    Emitter<ProductoFormState> emit,
  ) async {
    final codigoAnterior = state.codigo;
    final nombre = event.nombre ?? state.nombre;
    emit(
      state.copyWith(
        codigo: event.codigo,
        nombre: event.nombre,
        descripcion: event.descripcion,
        limpiarError: true,
      ),
    );

    if (state.editando || event.codigo != null || event.nombre == null) return;
    final nombreBase = nombre.trim();
    if (nombreBase.isEmpty) return;

    final prefijo = CodigoInternoGenerator.prefijoDesdeNombre(nombreBase);
    final codigoActual = state.codigo.trim().toUpperCase();
    final tienePrefijoActual = RegExp(
      '^${RegExp.escape(prefijo)}-\\d+\$',
    ).hasMatch(codigoActual);
    if (tienePrefijoActual) return;

    if (state.tipoRegistro != 'unico' &&
        state.variantes.isNotEmpty &&
        codigoAnterior.trim().isNotEmpty) {
      return;
    }

    try {
      final productos = await _repository.obtenerProductos();
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: nombreBase,
        codigosExistentes: productos
            .where((producto) => producto.id != state.productoId)
            .map((producto) => producto.codigo),
      );
      if (state.editando || state.nombre.trim() != nombreBase) return;
      emit(
        state.copyWith(
          codigo: codigo,
          variantes: state.tipoRegistro == 'unico'
              ? _actualizarCodigoProductoUnico(state.variantes, codigo)
              : null,
          limpiarError: true,
        ),
      );
    } catch (_) {
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: nombreBase,
        codigosExistentes: const [],
      );
      if (state.editando || state.nombre.trim() != nombreBase) return;
      emit(
        state.copyWith(
          codigo: codigo,
          variantes: state.tipoRegistro == 'unico'
              ? _actualizarCodigoProductoUnico(state.variantes, codigo)
              : null,
          limpiarError: true,
        ),
      );
    }
  }

  List<ProductoVariante> _actualizarCodigoProductoUnico(
    List<ProductoVariante> variantes,
    String codigo,
  ) {
    if (variantes.isEmpty) return variantes;
    return [
      variantes.first.copyWith(
        sku: CodigoInternoGenerator.codigoProductoUnico(codigo),
      ),
    ];
  }"""
form_bloc = replace_once(
    form_bloc,
    "  void _clasificacion(\n",
    family_method + "\n\n  void _clasificacion(\n",
    "método de generación de código",
)

old_product_builder = """  NuevoProducto _productoDesdeEstado({bool? activo}) => NuevoProducto(
    codigo: state.codigo.trim().isEmpty
        ? CodigoInternoGenerator.nuevoProducto()
        : state.codigo.trim().toUpperCase(),
    nombre: state.nombre.trim(),
    descripcion: state.descripcion.trim(),
    empresa: state.empresa!,
    marca: state.marca!,
    categoria: state.categoria!,
    subcategoria: state.subcategoria ?? '',
    tipoRegistro: state.tipoRegistro,
    atributos: state.atributos,
    variantes: state.variantes,
    presentaciones: state.presentaciones,
    ventaLogisticaContenido: state.ventaLogisticaContenido == null
        ? null
        : step4SalesDraftToMap(state.ventaLogisticaContenido!),
    preciosConfigurados: state.preciosConfigurados == null
        ? null
        : step5PricingDraftToMap(state.preciosConfigurados!),
    imagenesConfiguradas: state.imagenesConfiguradas == null
        ? null
        : step6ImagesDraftToMap(state.imagenesConfiguradas!),
    precios: state.precios,
    imagenesPaths: state.imagenesPaths,
    activo: activo ?? state.activo,
  );
"""
new_product_builder = """  NuevoProducto _productoDesdeEstado({bool? activo}) {
    final codigo = state.codigo.trim().isEmpty
        ? CodigoInternoGenerator.siguienteProducto(
            nombreBase: state.nombre,
            codigosExistentes: const [],
          )
        : state.codigo.trim().toUpperCase();
    final variantes = state.tipoRegistro == 'unico'
        ? _actualizarCodigoProductoUnico(state.variantes, codigo)
        : state.variantes;
    return NuevoProducto(
      codigo: codigo,
      nombre: state.nombre.trim(),
      descripcion: state.descripcion.trim(),
      empresa: state.empresa!,
      marca: state.marca!,
      categoria: state.categoria!,
      subcategoria: state.subcategoria ?? '',
      tipoRegistro: state.tipoRegistro,
      atributos: state.atributos,
      variantes: variantes,
      presentaciones: state.presentaciones,
      ventaLogisticaContenido: state.ventaLogisticaContenido == null
          ? null
          : step4SalesDraftToMap(state.ventaLogisticaContenido!),
      preciosConfigurados: state.preciosConfigurados == null
          ? null
          : step5PricingDraftToMap(state.preciosConfigurados!),
      imagenesConfiguradas: state.imagenesConfiguradas == null
          ? null
          : step6ImagesDraftToMap(state.imagenesConfiguradas!),
      precios: state.precios,
      imagenesPaths: state.imagenesPaths,
      activo: activo ?? state.activo,
    );
  }
"""
form_bloc = replace_once(
    form_bloc,
    old_product_builder,
    new_product_builder,
    "persistencia del código legible",
)

family_fields = r"""  Widget _familyFields(BuildContext context, {required bool compact}) {
    final code = TextFormField(
      key: ValueKey('familia_codigo_${state.codigo}'),
      initialValue: state.codigo,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Código de familia',
        hintText: 'PER-001',
        helperText: 'Se genera automáticamente desde el nombre.',
        prefixIcon: Icon(Icons.qr_code_2_rounded),
        border: OutlineInputBorder(),
      ),
    );
    final name = TextFormField(
      key: const Key('familia_nombre'),
      initialValue: state.nombre,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(nombre: value),
      ),
      decoration: const InputDecoration(
        labelText: 'Nombre de la familia *',
        hintText: 'Ej. Broca para metal HSS',
        border: OutlineInputBorder(),
      ),
    );
    final description = TextFormField(
      key: const Key('familia_descripcion'),
      initialValue: state.descripcion,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(descripcion: value),
      ),
      maxLines: compact ? 2 : 3,
      decoration: const InputDecoration(
        labelText: 'Descripción compartida (opcional)',
        hintText: 'Información que aplica a todas las variantes.',
        border: OutlineInputBorder(),
      ),
    );
    if (compact) {
      return Column(
        children: [
          code,
          const SizedBox(height: 10),
          name,
          const SizedBox(height: 10),
          description,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: code),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: name),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: description),
      ],
    );
  }"""
form_page = replace_between(
    form_page,
    "  Widget _familyFields(BuildContext context, {required bool compact}) {\n",
    "  Widget _typeOption(\n",
    family_fields,
    "campos de familia con código",
)

single_step = replace_once(
    single_step,
    """    _singleGeneratedSku = savedSku.isEmpty
        ? CodigoInternoGenerator.nuevaVariante()
        : savedSku.toUpperCase();
""",
    """    _singleGeneratedSku = savedSku.isEmpty
        ? CodigoInternoGenerator.codigoProductoUnico(widget.state.codigo)
        : savedSku.toUpperCase();
""",
    "código del producto único",
)

single_update = r"""  @override
  void didUpdateWidget(covariant ProductoUnicoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.editando ||
        oldWidget.state.codigo == widget.state.codigo) {
      return;
    }
    final codigo = CodigoInternoGenerator.codigoProductoUnico(
      widget.state.codigo,
    );
    if (_singleGeneratedSku == codigo) return;
    _singleGeneratedSku = codigo;
    _singleInternalCodeController.text = codigo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVariant();
    });
  }

"""
single_step = replace_once(
    single_step,
    "  @override\n  void dispose() {\n",
    single_update + "  @override\n  void dispose() {\n",
    "actualización del código del producto único",
)
single_step = replace_once(
    single_step,
    """                  hint: 'VAR-XXXXXXXXXX',
                  helper: 'Generado automáticamente. No es editable.',
""",
    """                  hint: 'PER-001',
                  helper:
                      'Generado automáticamente desde el nombre comercial.',
""",
    "texto del código único",
)

variants_step = replace_once(
    variants_step,
    "    _sku.text = CodigoInternoGenerator.nuevaVariante();\n",
    """    _sku.text = CodigoInternoGenerator.siguienteVariante(
      codigoFamilia: widget.state.codigo,
      codigosExistentes: widget.state.variantes.map((item) => item.sku),
    );
""",
    "código de nueva variante",
)
variants_step = replace_once(
    variants_step,
    """      sku: CodigoInternoGenerator.nuevaVariante(),
""",
    """      sku: CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: widget.state.codigo,
        codigosExistentes: widget.state.variantes.map((item) => item.sku),
      ),
""",
    "código de variante duplicada",
)
variants_step = replace_once(
    variants_step,
    """                hint: 'VAR-XXXXXXXXXX',
""",
    """                hint: 'PER-001-001',
""",
    "ejemplo del código de variante",
)

old_matrix_default = """  _MatrixCombinationDraft _createDefaultMatrixCombination({
    required String rowLabel,
    required String columnLabel,
    bool included = false,
  }) {
    final key = _MatrixCombinationDraft.buildKey(rowLabel, columnLabel);
    return _MatrixCombinationDraft(
      id: const Uuid().v4(),
      key: key,
      rowValue: rowLabel,
      columnValue: columnLabel,
      included: included,
      sku: CodigoInternoGenerator.nuevaVariante(),
      supplierCode: '',
      generatedName: '$_matrixFamilyLabel $columnLabel × $rowLabel',
      initialActive: true,
      attributes: const {},
    );
  }
"""
new_matrix_default = """  _MatrixCombinationDraft _createDefaultMatrixCombination({
    required String rowLabel,
    required String columnLabel,
    required Iterable<String> codigosExistentes,
    bool included = false,
  }) {
    final key = _MatrixCombinationDraft.buildKey(rowLabel, columnLabel);
    return _MatrixCombinationDraft(
      id: const Uuid().v4(),
      key: key,
      rowValue: rowLabel,
      columnValue: columnLabel,
      included: included,
      sku: CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: widget.state.codigo,
        codigosExistentes: codigosExistentes,
      ),
      supplierCode: '',
      generatedName: '$_matrixFamilyLabel $columnLabel × $rowLabel',
      initialActive: true,
      attributes: const {},
    );
  }
"""
matrix_step = replace_once(
    matrix_step,
    old_matrix_default,
    new_matrix_default,
    "código de combinación de matriz",
)
matrix_step = replace_once(
    matrix_step,
    """            _createDefaultMatrixCombination(
              rowLabel: row.label,
              columnLabel: column.label,
            );
""",
    """            _createDefaultMatrixCombination(
              rowLabel: row.label,
              columnLabel: column.label,
              codigosExistentes: [
                ..._matrixCombinations.values.map((item) => item.sku),
                ...nextCombinations.values.map((item) => item.sku),
              ],
            );
""",
    "reserva correlativa en la matriz",
)

code_test = r"""import 'package:app_catalogo/features/catalogo/domain/services/codigo_interno_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodigoInternoGenerator', () {
    test('crea prefijos legibles desde el nombre', () {
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Perno hexagonal'),
        'PER',
      );
      expect(CodigoInternoGenerator.prefijoDesdeNombre('Broca HSS'), 'BRO');
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Alicate universal'),
        'ALI',
      );
      expect(
        CodigoInternoGenerator.prefijoDesdeNombre('Disco de corte'),
        'DIS',
      );
    });

    test('genera el siguiente correlativo de familia', () {
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: 'Perno hexagonal',
        codigosExistentes: const [
          'PER-001',
          'PER-023',
          'PER-023-001',
          'BRO-100',
        ],
      );

      expect(codigo, 'PER-024');
    });

    test('genera variantes bajo el código de familia', () {
      final codigo = CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: 'PER-023',
        codigosExistentes: const [
          'PER-023-001',
          'PER-023-003',
          'PER-024-010',
        ],
      );

      expect(codigo, 'PER-023-004');
      expect(
        CodigoInternoGenerator.codigoProductoUnico('PER-023'),
        'PER-023',
      );
    });
  });
}
"""

pdf_test = r"""import 'dart:convert';

import 'package:app_catalogo/features/pedidos/data/services/cotizacion_pdf_service.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_detalle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera una cotización PDF válida', () async {
    final pedido = PedidoDetalle(
      id: 'pedido-1',
      codigo: 'PED-2026-0001',
      fecha: DateTime(2026, 8, 2),
      estado: 'Pendiente',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'cliente-1',
      clienteNombre: 'Ferretería Central S.A.C.',
      telefono: '987654321',
      clienteRuc: '20601234567',
      direccion: 'Av. Industrial 123, Arequipa',
      referencia: '',
      productos: const [],
      subtotalConocido: 118,
      productosSinPrecio: 0,
      hoja: 'HP-2026-001',
      vendedor: 'Alfonzo Esteban',
      estadoPreparacion: 'pendiente',
      estadoCarga: 'pendiente',
      historial: const [],
    );
    final cotizacion = CotizacionPedidoGuardada(
      id: 'cotizacion-1',
      pedidoId: pedido.id,
      codigo: 'COT-2026-0001',
      total: 118,
      creadoEn: DateTime(2026, 8, 2),
    );
    const producto = PedidoDetalleProducto(
      id: 'item-1',
      productoId: 'producto-1',
      codigo: 'PER-023',
      nombre: 'Perno hexagonal',
      presentacion: 'Ciento',
      equivalencia: '100 UND',
      cantidad: 2,
      precioUnitario: 59,
      subtotal: 118,
      varianteSku: 'PER-023-001',
      varianteNombre: 'Perno hexagonal 1/4 x 4',
      atributosVariante: {'Diámetro': '1/4 in', 'Largo': '4 in'},
    );

    final bytes = await CotizacionPdfService().generarBytes(
      cotizacion: cotizacion,
      pedido: pedido,
      productos: const [
        CotizacionPdfProducto(
          producto: producto,
          precioUnitarioConIgv: 59,
          subtotalConIgv: 118,
        ),
      ],
      subtotalProductos: 118,
      descuentosProductos: 0,
      descuentoGeneral: 0,
      total: 118,
      observaciones: 'Entrega sujeta a confirmación.',
    );

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1500));
  });
}
"""

updates = {
    PUBSPEC: pubspec,
    QUOTE_DIALOG: quote_dialog,
    CODE_GENERATOR: generator,
    FORM_BLOC: form_bloc,
    FORM_PAGE: form_page,
    SINGLE_STEP: single_step,
    VARIANTS_STEP: variants_step,
    MATRIX_STEP: matrix_step,
}

new_files = {
    PDF_SERVICE: pdf_service,
    CODE_TEST: code_test,
    PDF_TEST: pdf_test,
}

# ---------------------------------------------------------------------------
# Validaciones finales antes de escribir.
# ---------------------------------------------------------------------------
required_results = {
    PUBSPEC: ["pdf: ^3.13.0"],
    QUOTE_DIALOG: [
        "CotizacionPdfService",
        "CotizacionPdfProducto",
    ],
    CODE_GENERATOR: [
        "prefijoDesdeNombre",
        "siguienteProducto",
        "siguienteVariante",
    ],
    FORM_BLOC: [
        "_familiaCambiada",
        "_actualizarCodigoProductoUnico",
    ],
    FORM_PAGE: ["Código de familia", "PER-001"],
    SINGLE_STEP: [
        "codigoProductoUnico",
        "Generado automáticamente desde el nombre comercial.",
    ],
    VARIANTS_STEP: [
        "siguienteVariante",
        "PER-001-001",
    ],
    MATRIX_STEP: [
        "required Iterable<String> codigosExistentes",
        "...nextCombinations.values.map((item) => item.sku)",
    ],
}
for path, markers in required_results.items():
    content = updates[path]
    for marker in markers:
        if marker not in content:
            fail(
                f"El resultado de {path.relative_to(ROOT)} "
                f"no contiene: {marker}"
            )

if "_CotizacionPdfExporter" in quote_dialog:
    fail("Permanece el exportador PDF manual.")
if "dart:convert" in quote_dialog or "path_provider" in quote_dialog:
    fail("Permanecen imports del exportador PDF anterior.")

combined_lib = []
for dart_file in (ROOT / "lib").rglob("*.dart"):
    if dart_file in updates:
        combined_lib.append(updates[dart_file])
    else:
        combined_lib.append(dart_file.read_text(encoding="utf-8"))
combined_lib.extend(new_files.values())
combined_text = "\n".join(combined_lib)
for obsolete in (
    "CodigoInternoGenerator.nuevoProducto()",
    "CodigoInternoGenerator.nuevaVariante()",
):
    if obsolete in combined_text:
        fail(f"Permanece una llamada antigua: {obsolete}")

backup_dir = ROOT / (
    ".backup_pdf_codigos_producto_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

for path, content in new_files.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Creado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nAplicados:")
print("- PDF profesional MULTIMARCA con tabla, observaciones e IGV.")
print("- Códigos de familia correlativos: PER-001, BRO-001, etc.")
print("- Códigos de variantes: PER-001-001, PER-001-002, etc.")
print("- Producto único usa el mismo código de la familia.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta primero:")
print("  flutter pub get")
print("  dart format lib test")
print("  flutter test test/codigo_interno_generator_test.dart")
print("  flutter test test/cotizacion_pdf_service_test.dart")
print("  flutter test test/pedidos_page_test.dart")
print("  flutter analyze")
