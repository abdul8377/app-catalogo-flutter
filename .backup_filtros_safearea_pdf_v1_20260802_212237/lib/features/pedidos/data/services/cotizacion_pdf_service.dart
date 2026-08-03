import 'dart:io';
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
              _lineaCliente('Dirección de entrega:', pedido.direccion.trim()),
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
            _bodyCell('${item.producto.cantidad}', align: pw.TextAlign.center),
            _bodyCell(
              _money(CotizacionIgv.totalSinIgv(item.precioUnitarioConIgv)),
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

  pw.Widget _bodyCell(String value, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
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
        pw.Text(producto.presentacion, style: const pw.TextStyle(fontSize: 7)),
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
              _totalRow('TOTAL CON IGV', _money(total), highlighted: true),
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
